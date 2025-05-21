#!/bin/bash

# ========= 色彩定义 =========
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

# ========= 项目路径 =========
NCK_DIR="$HOME/nockchain"

# ========= 横幅与署名 =========
function show_banner() {
  clear
  echo -e "${BOLD}${BLUE}"
  echo "               ╔═╗╔═╦╗─╔╦═══╦═══╦═══╦═══╗"
  echo "               ╚╗╚╝╔╣║─║║╔══╣╔═╗║╔═╗║╔═╗║"
  echo "               ─╚╗╔╝║║─║║╚══╣║─╚╣║─║║║─║║"
  echo "               ─╔╝╚╗║║─║║╔══╣║╔═╣╚═╝║║─║║"
  echo "               ╔╝╔╗╚╣╚═╝║╚══╣╚╩═║╔═╗║╚═╝║"
  echo "               ╚═╝╚═╩═══╩═══╩═══╩╝─╚╩═══╝"
  echo -e "${RESET}"
  echo "               关注TG频道：t.me/xuegaoz"
  echo "               我的GitHub：github.com/Gzgod"
  echo "               我的推特：推特雪糕战神@Xuegaogx"
  echo "-----------------------------------------------"
  echo ""
}

# ========= 检查 macOS 环境 =========
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}[-] 此脚本仅适用于 macOS 系统！${RESET}"
  exit 1
fi

# ========= 安装 Homebrew =========
function install_homebrew() {
  if command -v brew &> /dev/null; then
    echo -e "${YELLOW}[!] Homebrew 已安装，跳过安装。${RESET}"
    return
  fi
  echo -e "[*] 安装 Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Homebrew 安装失败，请手动安装！${RESET}"
    pause_and_return
    return
  fi
  echo -e "${GREEN}[+] Homebrew 安装完成。${RESET}"
}

# ========= 安装系统依赖 =========
function install_dependencies() {
  install_homebrew
  echo -e "[*] 安装系统依赖..."
  brew install git curl wget make automake autoconf pkg-config openssl lz4 jq tmux llvm
  if [ $? -ne 0 ]; then
    echo -e "${RED}[-] 依赖安装失败，请检查 Homebrew 或网络！${RESET}"
    pause_and_return
    return
  fi
  echo -e "${GREEN}[+] 依赖安装完成。${RESET}"
  pause_and_return
}

# ========= 安装 Rust =========
function install_rust() {
  if command -v rustc &> /dev/null; then
    echo -e "${YELLOW}[!] Rust 已安装，跳过安装。${RESET}"
    pause_and_return
    return
  fi
  echo -e "[*] 安装 Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  rustup default stable
  if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Rust 安装失败，请手动安装！${RESET}"
    pause_and_return
    return
  fi
  echo -e "${GREEN}[+] Rust 安装完成。${RESET}"
  pause_and_return
}

# ========= 克隆或更新仓库 =========
function setup_repository() {
  echo -e "[*] 检查 nockchain 仓库..."
  if [ -d "$NCK_DIR" ]; then
    echo -e "${YELLOW}[?] 已存在 nockchain 目录，是否删除重新克隆？(y/n)${RESET}"
    read -r confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
      rm -rf "$NCK_DIR"
      git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
      if [ $? -ne 0 ]; then
        echo -e "${RED}[-] 克隆仓库失败，请检查网络或权限！${RESET}"
        pause_and_return
        return
      fi
    else
      cd "$NCK_DIR" && git pull
    fi
  else
    git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
    if [ $? -ne 0 ]; then
      echo -e "${RED}[-] 克隆仓库失败，请检查网络或权限！${RESET}"
      pause_and_return
      return
    fi
  fi
  echo -e "${GREEN}[+] 仓库设置完成。${RESET}"
  pause_and_return
}

# ========= 编译项目 =========
function build_project() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先设置仓库！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  read -p "[?] 请输入用于编译的 CPU 核心数量: " CORE_COUNT
  if ! [[ "$CORE_COUNT" =~ ^[0-9]+$ ]] || [[ "$CORE_COUNT" -lt 1 ]]; then
    echo -e "${RED}[-] 输入无效，默认使用 1 核心。${RESET}"
    CORE_COUNT=1
  fi

  echo -e "[*] 编译核心组件，使用 ${CORE_COUNT} 核心..."
  make -j$CORE_COUNT install-hoonc
  make -j$CORE_COUNT build
  make -j$CORE_COUNT install-nockchain-wallet
  make -j$CORE_COUNT install-nockchain
  echo -e "${GREEN}[+] 编译完成。${RESET}"
  pause_and_return
}

# ========= 配置环境变量 =========
function configure_env() {
  echo -e "[*] 配置环境变量..."
  RC_FILE="$HOME/.zshrc"  # macOS 默认使用 zsh
  [[ "$SHELL" == *"bash"* ]] && RC_FILE="$HOME/.bashrc"

  if ! grep -q "$HOME/nockchain/target/release" "$RC_FILE"; then
    echo 'export PATH="$PATH:$HOME/nockchain/target/release"' >> "$RC_FILE"
  fi
  if ! grep -q "LIBCLANG_PATH" "$RC_FILE"; then
    echo 'export LIBCLANG_PATH=$(brew --prefix llvm)/lib' >> "$RC_FILE"
  fi
  source "$RC_FILE"
  export LIBCLANG_PATH=$(brew --prefix llvm)/lib
  echo -e "${GREEN}[+] 环境变量配置完成。${RESET}"
  pause_and_return
}

# ========= 生成钱包 =========
function generate_wallet() {
  if [ ! -d "$NCK_DIR" ] || [ ! -f "$NCK_DIR/target/release/nockchain-wallet" ]; then
    echo -e "${RED}[-] 未找到钱包命令或 nockchain 目录，请确保编译成功！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  echo -e "[*] 生成钱包密钥对..."
  WALLET_CMD="./target/release/nockchain-wallet"
  
  # Run keygen and capture output
  KEYGEN_OUTPUT=$("$WALLET_CMD" keygen 2>&1 | tr -d '\0')
  if [ $? -ne 0 ]; then
    echo -e "${RED}[-] 密钥生成失败！${RESET}"
    echo "$KEYGEN_OUTPUT" > "$NCK_DIR/wallet.txt"
    echo -e "[*] 错误输出已保存至 $NCK_DIR/wallet.txt"
    pause_and_return
    return
  fi

  # Save output to wallet.txt
  echo "$KEYGEN_OUTPUT" > "$NCK_DIR/wallet.txt"
  echo -e "[*] 密钥对已保存至 $NCK_DIR/wallet.txt"

  # Extract public key (adjust regex based on actual output format)
  PUBLIC_KEY=$(echo "$KEYGEN_OUTPUT" | grep -i "public key" | awk '{print $NF}')
  if [ -z "$PUBLIC_KEY" ]; then
    echo -e "${RED}[-] 无法提取公钥，请检查输出！${RESET}"
    pause_and_return
    return
  fi
  echo -e "${YELLOW}公钥:${RESET}\n$PUBLIC_KEY"
  echo -e "${YELLOW}[!] 请手动将以下公钥添加到 $NCK_DIR/Makefile 中：${RESET}"
  echo -e "export MINING_PUBKEY := $PUBLIC_KEY"
  echo -e "${YELLOW}[!] 你可以使用菜单选项 '7) 设置挖矿公钥' 或手动编辑 Makefile。${RESET}"

  echo -e "${GREEN}[+] 钱包生成完成。${RESET}"
  pause_and_return
}

# ========= 设置挖矿公钥 =========
function configure_mining_key() {
  if [ ! -f "$NCK_DIR/Makefile" ]; then
    echo -e "${RED}[-] 找不到 Makefile 文件，无法设置公钥！${RESET}"
    pause_and_return
    return
  fi

  read -p "[?] 输入你的挖矿公钥 / Enter your mining public key: " key
  cd "$NCK_DIR" || exit 1
  if grep -q "MINING_PUBKEY" Makefile; then
    sed -i '' "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $key|" Makefile
  else
    echo "export MINING_PUBKEY := $key" >> Makefile
  fi
  echo -e "${GREEN}[+] 挖矿公钥已设置 / Mining key updated.${RESET}"
  pause_and_return
}

# ========= 管理密钥（备份/导入） =========
function manage_keys() {
  echo ""
  echo "密钥管理:"
  echo "  1) 备份密钥"
  echo "  2) 导入密钥"
  echo "  0) 返回主菜单"
  echo ""
  read -p "选择操作: " key_choice
  case "$key_choice" in
    1)
      cd "$NCK_DIR" || exit 1
      if [ -f "$NCK_DIR/target/release/nockchain-wallet" ]; then
        echo -e "[*] 备份密钥..."
        ./target/release/nockchain-wallet export-keys
        if [ -f "keys.export" ]; then
          echo -e "${GREEN}[+] 密钥已备份至 $NCK_DIR/keys.export${RESET}"
        else
          echo -e "${RED}[-] 密钥备份失败！${RESET}"
        fi
      else
        echo -e "${RED}[-] 未找到钱包命令，请确保编译成功！${RESET}"
      fi
      ;;
    2)
      cd "$NCK_DIR" || exit 1
      if [ -f "$NCK_DIR/target/release/nockchain-wallet" ]; then
        if [ -f "keys.export" ]; then
          echo -e "[*] 导入密钥..."
          ./target/release/nockchain-wallet import-keys --input keys.export
          echo -e "${GREEN}[+] 密钥导入完成。${RESET}"
        else
          echo -e "${RED}[-] 未找到 keys.export 文件！${RESET}"
        fi
      else
        echo -e "${RED}[-] 未找到钱包命令，请确保编译成功！${RESET}"
      fi
      ;;
    0) return ;;
    *) echo -e "${RED}[-] 无效选项。${RESET}" ;;
  esac
  pause_and_return
}

# ========= 启动 Leader 节点 =========
function start_leader_node() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先设置仓库！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  echo -e "[*] 启动 Leader 节点..."
  tmux new-session -d -s leader "make run-nockchain-leader"
  echo -e "${GREEN}[+] Leader 节点运行中。${RESET}"
  echo -e "${YELLOW}[!] 正在进入日志界面，按 Ctrl+B 然后 D 可退出。${RESET}"
  sleep 2
  tmux attach-session -t leader
  pause_and_return
}

# ========= 启动 Follower 节点 =========
function start_follower_node() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先设置仓库！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  echo -e "[*] 启动 Follower 节点..."
  tmux new-session -d -s follower "make run-nockchain-follower"
  echo -e "${GREEN}[+] Follower 节点运行中。${RESET}"
  echo -e "${YELLOW}[!] 正在进入日志界面，按 Ctrl+B 然后 D 可退出。${RESET}"
  sleep 2
  tmux attach-session -t follower
  pause_and_return
}

# ========= 启动 Miner 节点 =========
function start_miner_node() {
  if [ ! -d "$NCK_DIR" ]; then
    echo -e "${RED}[-] nockchain 目录不存在，请先设置仓库！${RESET}"
    pause_and_return
    return
  fi

  cd "$NCK_DIR" || exit 1
  echo -e "[*] 启动 Miner 节点..."
  tmux new-session -d -s miner "make run-nockchain"
  echo -e "${GREEN}[+] Miner 节点运行中。${RESET}"
  echo -e "${YELLOW}[!] 正在进入日志界面，按 Ctrl+B 然后 D 可退出。${RESET}"
  sleep 2
  tmux attach-session -t miner
  pause_and_return
}

# ========= 查看节点日志 =========
function view_logs() {
  echo ""
  echo "查看节点日志:"
  echo "  1) Leader 节点"
  echo "  2) Follower 节点"
  echo "  3) Miner 节点"
  echo "  0) 返回主菜单"
  echo ""
  read -p "选择查看哪个节点日志: " log_choice
  case "$log_choice" in
    1)
      if tmux list-sessions | grep -q "leader"; then
        tmux attach-session -t leader
      else
        echo -e "${RED}[-] Leader 节点未运行。${RESET}"
      fi
      ;;
    2)
      if tmux list-sessions | grep -q "follower"; then
        tmux attach-session -t follower
      else
        echo -e "${RED}[-] Follower 节点未运行。${RESET}"
      fi
      ;;
    3)
      if tmux list-sessions | grep -q "miner"; then
        tmux attach-session -t miner
      else
        echo -e "${RED}[-] Miner 节点未运行。${RESET}"
      fi
      ;;
    0) return ;;
    *) echo -e "${RED}[-] 无效选项。${RESET}" ;;
  esac
  pause_and_return
}

# ========= 等待任意键继续 =========
function pause_and_return() {
  echo ""
  read -n1 -r -p "按任意键返回主菜单..." key
  main_menu
}

# ========= 主菜单 =========
function main_menu() {
  show_banner
  echo "请选择操作:"
  echo "  1) 安装系统依赖"
  echo "  2) 安装 Rust"
  echo "  3) 设置仓库"
  echo "  4) 编译项目"
  echo "  5) 配置环境变量"
  echo "  6) 生成钱包"
  echo "  7) 设置挖矿公钥"
  echo "  8) 启动 Leader 节点（不需要）"
  echo "  9) 启动 Follower 节点（不需要）"
  echo "  10) 启动 Miner 节点（上面的跑完直接跑这个）"
  echo "  11) 查看节点日志"
  echo "  12) 管理密钥（备份/导入）"
  echo "  0) 退出"
  echo ""
  read -p "请输入编号: " choice

  case "$choice" in
    1) install_dependencies ;;
    2) install_rust ;;
    3) setup_repository ;;
    4) build_project ;;
    5) configure_env ;;
    6) generate_wallet ;;
    7) configure_mining_key ;;
    8) start_leader_node ;;
    9) start_follower_node ;;
    10) start_miner_node ;;
    11) view_logs ;;
    12) manage_keys ;;
    0) echo "已退出。"; exit 0 ;;
    *) echo -e "${RED}[-] 无效选项。${RESET}"; pause_and_return ;;
  esac
}

# ========= 启动主程序 =========
main_menu
