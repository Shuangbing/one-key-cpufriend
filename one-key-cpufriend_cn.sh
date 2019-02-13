#!/bin/bash
# stevezhengshiqi 创建于2019年2月8日。
# 暂时只支持大部分5代-8代U, 更老的CPU不使用X86PlatformPlugin.kext。
# 此脚本很依赖于 CPUFriend(https://github.com/acidanthera/CPUFriend), 感谢 Acidanthera 和 PMHeart。

# 界面 (参考: http://patorjk.com/software/taag/#p=display&f=Ivrit&t=C%20P%20U%20F%20R%20I%20E%20N%20D)
function interface(){
    printf "\e[8;40;110t"
    boardid=($(ioreg -lw0 | grep -i "board-id" | sed -e "/[^<]*</s///" -e "s/\>//" | sed 's/"//g'))
    support=0
    echo "  ____   ____    _   _   _____   ____    ___   _____   _   _   ____ "
    echo " / ___| |  _ \  | | | | |  ___| |  _ \  |_ _| | ____| | \ | | |  _ \ "
    echo "| |     | |_) | | | | | | |_    | |_) |  | |  |  _|   |  \| | | | | | "
    echo "| |___  |  __/  | |_| | |  _|   |  _ <   | |  | |___  | |\  | | |_| | "
    echo " \____| |_|      \___/  |_|     |_| \_\ |___| |_____| |_| \_| |____/ "
    echo "你的board-id是 $boardid"
    echo "===================================================================== "
}

# 如果网络异常，退出
function networkwarn(){
    echo "ERROR: 下载CPUFriend失败, 请检查网络状态"
    exit 0
}

# 下载CPUFriend仓库并解压最新release
function download(){
    mkdir -p Desktop/tmp/one-key-cpufriend
    cd Desktop/tmp/one-key-cpufriend
    echo "--------------------------------------------------------------------"
    echo "|* 正在下载CPUFriend，源自github.com/acidanthera/CPUFriend @PMHeart *|"
    echo "--------------------------------------------------------------------"
    curl -fsSL https://raw.githubusercontent.com/acidanthera/CPUFriend/master/ResourceConverter/ResourceConverter.sh -o ./ResourceConverter.sh || networkwarn
    sudo chmod +x ./ResourceConverter.sh
    curl -fsSL https://github.com/acidanthera/CPUFriend/releases/download/1.1.6/1.1.6.RELEASE.zip -o ./1.1.6.RELEASE.zip && unzip 1.1.6.RELEASE.zip && cp -r CPUFriend.kext ../../ || networkwarn
}

# 检查board-id
function checkboardid(){
    if [ $boardid = "Mac-BE0E8AC46FE800CC" -o $boardid = "Mac-9F18E312C5C2BF0B" -o $boardid = "Mac-937CB26E2E02BB01" -o $boardid = "Mac-E43C1C25D4880AD6" -o $boardid = "Mac-A369DDC4E67F1C45" -o $boardid = "Mac-FFE5EF870D7BA81A" -o $boardid = "Mac-4B682C642B45593E" -o $boardid = "Mac-77F17D7DA9285301" ]; then
        support=1
    elif [ $boardid = "Mac-9AE82516C7C6B903" -o $boardid = "Mac-EE2EBD4B90B839A8" -o $boardid = "Mac-473D31EABEB93F9B" -o $boardid = "Mac-66E35819EE2D0D05" -o $boardid = "Mac-A5C67F76ED83108C" -o $boardid = "Mac-B4831CEBD52A0C4C" -o $boardid = "Mac-CAD6701F7CEA0921" -o $boardid = "Mac-551B86E5744E2388" -o $boardid = "Mac-937A206F2EE63C01" -o $boardid = "Mac-827FB448E656EC26" ]; then
        support=2
    else
        support=0
    fi
}

# 复制目标plist
function copyplist(){
    sudo cp -r /System/Library/Extensions/IOPlatformPluginFamily.kext/Contents/PlugIns/X86PlatformPlugin.kext/Contents/Resources/$boardid.plist ./
}

# 修改LFM值来调整最低频率
function changelfm(){
    echo "----------------------------"
    echo "|****** 选择低频率模式 ******|"
    echo "----------------------------"
    echo "(1) 保持不变 (1200/1300mhz)"
    echo "(2) 800mhz (低负载下更省电)"
    read -p "你想选择哪个选项? (1/2):" lfm_selection
    case $lfm_selection in
        1)
        # 保持不变
        ;;

        2)
        # 把 1200/1300 改成 800
        sudo /usr/bin/sed -i "" "s:AgAAAA0AAAA:AgAAAAgAAAA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:AgAAAAwAAAA:AgAAAAgAAAA:g" $boardid.plist
        ;;

        *)
        echo "ERROR: 输入有误, 脚本将退出"
        exit 0
        ;;
    esac
}

# 修改EPP值来调节性能模式 (参考: https://www.tonymacx86.com/threads/skylake-hwp-enable.214915/page-7)
function changeepp(){
    echo "--------------------------"
    echo "|****** 选择性能模式 ******|"
    echo "--------------------------"
    echo "(1) 最省电模式"
    echo "(2) 平衡电量模式 (默认)"
    echo "(3) 平衡性能模式"
    echo "(4) 高性能模式"
    read -p "你想选择哪个模式? (1/2/3/4):" epp_selection
    case $epp_selection in
        1)
        # 把 80/90/92 改成 C0, 最省电模式
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:DAAAAAAAAAAAAAAAAAAAAAd:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:DAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAADA:g" $boardid.plist
        ;;

        2)
        # 保持默认值 80/90/92, 平衡电量模式
        ;;

        3)
        # 把 80/90/92 改成 40, 平衡性能模式
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:BAAAAAAAAAAAAAAAAAAAAAd:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:BAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAABA:g" $boardid.plist
        ;;

        4)
        # 把 80/90/92 改成 00, 高性能模式
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CAAAAAAAAAAAAAAAAAAAAAd:AAAAAAAAAAAAAAAAAAAAAAd:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CSAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:CQAAAAAAAAAAAAAAAAAAAAc:AAAAAAAAAAAAAAAAAAAAAAc:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACS:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" $boardid.plist
        sudo /usr/bin/sed -i "" "s:ZXBwAAAAAAAAAAAAAAAAAAAAAACA:ZXBwAAAAAAAAAAAAAAAAAAAAAAAA:g" $boardid.plist
        ;;

        *)
        echo "ERROR: 输入有误, 脚本将退出"
        exit 0
        ;;
    esac
}

# 生成 CPUFriendDataProvider.kext 并复制到桌面
function generatekext(){
    echo "正在生成CPUFriendDataProvider.kext"
    sudo ./ResourceConverter.sh --kext $boardid.plist
    cp -r CPUFriendDataProvider.kext ../../
}

# 删除tmp文件夹并结束
function clean(){
    sudo rm -rf ../../tmp

    echo "很棒！脚本运行结束, 请把桌面上的CPUFriend和CPUFriendDataProvider放入/CLOVER/kexts/Other/下"
    exit 0
}

# 主程序
function main(){
    interface
    echo " "
    download
    echo " "
    checkboardid
    if [ $support == 1 ];then
        copyplist
        changelfm
    elif [ $support == 2 ];then
        copyplist
        changelfm
        echo " "
        changeepp
    else
        echo "抱歉啦，这个脚本还不支持你的board-id"
        exit 0
    fi
    echo " "
    generatekext
    echo " "
    clean
    exit 0
}

main
