#云编译公用核心
name: WRT-CORE

on:
  workflow_call:
    inputs:
      WRT_TARGET:
        required: true
        type: string
      WRT_THEME:
        required: true
        type: string
      WRT_NAME:
        required: true
        type: string
      WRT_SSID:
        required: true
        type: string
      WRT_WORD:
        required: true
        type: string
      WRT_IP:
        required: true
        type: string
      WRT_PW:
        required: true
        type: string
      WRT_REPO:
        required: true
        type: string
      WRT_BRANCH:
        required: true
        type: string
      WRT_SOURCE:
        required: false
        type: string
      WRT_PACKAGE:
        required: false
        type: string
      WRT_TEST:
        required: false
        type: string

env:
  GITHUB_TOKEN: ${{secrets.GITHUB_TOKEN}}
  WRT_TARGET: ${{inputs.WRT_TARGET}}
  WRT_THEME: ${{inputs.WRT_THEME}}
  WRT_NAME: ${{inputs.WRT_NAME}}
  WRT_SSID: ${{inputs.WRT_SSID}}
  WRT_WORD: ${{inputs.WRT_WORD}}
  WRT_IP: ${{inputs.WRT_IP}}
  WRT_PW: ${{inputs.WRT_PW}}
  WRT_REPO: ${{inputs.WRT_REPO}}
  WRT_BRANCH: ${{inputs.WRT_BRANCH}}
  WRT_PACKAGE: ${{inputs.WRT_PACKAGE}}
  WRT_TEST: ${{inputs.WRT_TEST}}

jobs:
  core:
    name: ${{inputs.WRT_SOURCE}}
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout Projects(结算项目)
        uses: actions/checkout@main

      - name: Free Disk Space(清理磁盘空间)
        uses: endersonmenezes/free-disk-space@main
        with:
          testing: false
          remove_android: true
          remove_dotnet: true
          remove_haskell: true
          remove_tool_cache: true
          remove_swap: true
          remove_packages: "android* azure* clang* dotnet* firefox* ghc* golang* google* libclang* libgl1* lld* llvm* \
            microsoft* mongodb* mono* mysql* nodejs* openjdk* php* postgresql* powershell* snap* temurin* yarn* zulu*"
          remove_packages_one_command: true
          remove_folders: "/etc/apt/sources.list.d* /etc/mono* /etc/mysql* /usr/include/linux/android* /usr/lib/llvm* /usr/lib/mono* \
            /usr/local/lib/android* /usr/local/lib/node_modules* /usr/local/share/chromium* /usr/local/share/powershell* \
            /usr/local/share/vcpkg/ports/azure* /usr/local/share/vcpkg/ports/google* /usr/local/share/vcpkg/ports/libpq/android* \
            /usr/local/share/vcpkg/ports/llvm* /usr/local/share/vcpkg/ports/mysql* /usr/local/share/vcpkg/ports/snap* \
            /usr/share/azure* /usr/share/dotnet* /usr/share/glade* /usr/share/miniconda* /usr/share/php* /usr/share/swift \
            /var/lib/mysql* /var/log/azure*"

      - name: Initialization Environment(初始化环境)
        env:
          DEBIAN_FRONTEND: noninteractive
        run: |
          docker rmi $(docker images -q)
          sudo -E apt -yqq update
          sudo -E apt -yqq full-upgrade
          sudo -E apt -yqq autoremove --purge
          sudo -E apt -yqq autoclean
          sudo -E apt -yqq clean
          sudo -E apt -yqq install dos2unix libfuse-dev
          sudo bash -c 'bash <(curl -sL https://build-scripts.immortalwrt.org/init_build_environment.sh)'
          sudo apt-get install -yqq clang-15
          sudo -E systemctl daemon-reload
          sudo -E timedatectl set-timezone "Asia/Shanghai"

      - name: Initialization Values(初始化变量)
        run: |
          export WRT_DATE=$(TZ=UTC-8 date +"%y.%m.%d_%H.%M.%S")
          export WRT_CI=$(basename $GITHUB_WORKSPACE)
          export WRT_VER=$(echo $WRT_REPO | cut -d '/' -f 5-)-$WRT_BRANCH
          export WRT_TYPE=$(sed -n "1{s/^#//;s/\r$//;p;q}" $GITHUB_WORKSPACE/Config/$WRT_TARGET.txt)

          echo "WRT_DATE=$WRT_DATE" >> $GITHUB_ENV
          echo "WRT_CI=$WRT_CI" >> $GITHUB_ENV
          echo "WRT_VER=$WRT_VER" >> $GITHUB_ENV
          echo "WRT_TYPE=$WRT_TYPE" >> $GITHUB_ENV

      - name: Clone Code(拉取源码)
        run: |
          git clone --depth=1 --single-branch --branch $WRT_BRANCH $WRT_REPO ./wrt/

          cd ./wrt/ && echo "WRT_HASH=$(git log -1 --pretty=format:'%h')" >> $GITHUB_ENV

      - name: Check Scripts(检查代码)
        run: |
          find ./ -maxdepth 3 -type f -iregex ".*\(txt\|sh\)$" -exec dos2unix {} \; -exec chmod +x {} \;

      - name: Check Caches(检查缓存)
        id: check-cache
        if: env.WRT_TEST != 'true'
        uses: actions/cache@main
        with:
          key: ${{env.WRT_TARGET}}-${{env.WRT_VER}}-${{env.WRT_HASH}}
          restore-keys: ${{env.WRT_TARGET}}-${{env.WRT_VER}}
          path: |
            ./wrt/.ccache
            ./wrt/staging_dir/host*
            ./wrt/staging_dir/tool*

      - name: Update Caches(更新缓存)
        if: env.WRT_TEST != 'true'
        run: |
          if [ -d "./wrt/staging_dir" ]; then
            find "./wrt/staging_dir" -type d -name "stamp" -not -path "*target*" | while read -r DIR; do
              find "$DIR" -type f -exec touch {} +
            done

            mkdir -p ./wrt/tmp && echo "1" > ./wrt/tmp/.build

            echo "toolchain skiped done!"
          else
            echo "caches missed!"
          fi

          if ${{steps.check-cache.outputs.cache-hit != 'true'}}; then
            CACHE_LIST=$(gh cache list --key "$WRT_TARGET-$WRT_VER" | cut -f 1)
            for CACHE_KEY in $CACHE_LIST; do
               gh cache delete $CACHE_KEY
            done

            echo "caches cleanup done!"
          fi

      - name: Update Feeds(更新依赖源)
        run: |
          cd ./wrt/

          ./scripts/feeds update -a
          ./scripts/feeds install -a

      - name: Custom Packages(自定义替换软件包)
        run: |
          cd ./wrt/package/

          $GITHUB_WORKSPACE/Scripts/Packages.sh
          $GITHUB_WORKSPACE/Scripts/Handles.sh

      - name: Custom Settings(自定义设置)
        run: |
          cd ./wrt/

          cat $GITHUB_WORKSPACE/Config/$WRT_TARGET.txt $GITHUB_WORKSPACE/Config/GENERAL.txt >> .config

          $GITHUB_WORKSPACE/Scripts/Settings.sh

          make defconfig -j$(nproc)

      - name: Download Packages(下载依赖)
        if: env.WRT_TEST != 'true'
        run: |
          cd ./wrt/

          make download -j$(nproc)

      - name: Compile Firmware(编译固件)
        if: env.WRT_TEST != 'true'
        run: |
          cd ./wrt/

          make -j$(nproc) || make -j1 V=s

      - name: Machine Information(设备信息)
        run: |
          cd ./wrt/

          echo "======================="
          lscpu | grep -E "name|Core|Thread"
          echo "======================="
          df -h
          echo "======================="
          du -h --max-depth=1
          echo "======================="

      - name: Package Firmware(打包固件)
        run: |
          cd ./wrt/ && mkdir ./upload/

          cp -f ./.config ./upload/Config_"$WRT_TARGET"_"$WRT_VER"_"$WRT_DATE".txt

          if [[ $WRT_TEST != 'true' ]]; then
            KVER=$(find ./bin/targets/ -type f -name "*.manifest" -exec grep -oP '^kernel - \K[\d\.]+' {} \;)

            find ./bin/targets/ -iregex ".*\(buildinfo\|json\|manifest\|sha256sums\|packages\)$" -exec rm -rf {} +

            for TYPE in $WRT_TYPE ; do
              for FILE in $(find ./bin/targets/ -type f -iname "*$TYPE*.*") ; do
                EXT=$(basename $FILE | cut -d '.' -f 2-)
                NAME=$(basename $FILE | cut -d '.' -f 1 | grep -io "\($TYPE\).*")
                NEW_FILE="$WRT_VER"_"$NAME"_"$WRT_DATE"."$EXT"
                mv -f $FILE ./upload/$NEW_FILE
              done
            done

            find ./bin/targets/ -type f -exec mv -f {} ./upload/ \;
          fi

          echo "WRT_KVER=${KVER:-none}" >> $GITHUB_ENV

      - name: Release Firmware(发布固件)
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{env.WRT_TARGET}}_${{env.WRT_VER}}_${{env.WRT_DATE}}
          files: ./wrt/upload/*.*
          body: |
            这是个平台固件包，内含多个设备！
            请注意选择你需要的设备固件！
            不要问，刷就完事了！

            全系带开源硬件加速，别问了！

            内核版本：${{env.WRT_KVER}}

            WIFI名称：${{env.WRT_SSID}}
            WIFI密码：${{env.WRT_WORD}}

            源码：${{env.WRT_REPO}}
            分支：${{env.WRT_BRANCH}}
            平台：${{env.WRT_TARGET}}
            设备：${{env.WRT_TYPE}}
            地址：${{env.WRT_IP}}
            密码：${{env.WRT_PW}}
