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

# ========= 安装系统依赖 =========
function install_dependencies() {
  echo -e "[*] 安装系统依赖..."
  apt-get update && apt install -y sudo
  sudo apt install -y screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
  echo -e "${GREEN}[+] 依赖安装完成。${RESET}"
  pause_and_return
}

# ========= 安装 Rust =========
function install_rust() {
  echo -e "[*] 安装 Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
  rustup default stable
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
    else
      cd "$NCK_DIR" && git pull
    fi
  else
    git clone https://github.com/zorp-corp/nockchain "$NCK_DIR"
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
  RC_FILE="$HOME/.bashrc"
  [[ "$SHELL" == *"zsh"* ]] && RC_FILE="$HOME/.zshrc"

  echo 'export PATH="$PATH:$HOME/nockchain/target/release"' >> "$RC_FILE"
  echo 'export RUST_LOG=info' >> "$RC_FILE"
  echo 'export MINIMAL_LOG_FORMAT=true' >> "$RC_FILE"
  source "$RC_FILE"
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
  echo -e "[*] 自动生成钱包助记词与主私钥..."
  WALLET_CMD="./target/release/nockchain-wallet"
  
  # 生成种子短语并直接捕获输出
  SEED_OUTPUT=$("$WALLET_CMD" keygen 2>&1 | tr -d '\0')
  if [ $? -ne 0 ]; then
    echo -e "${RED}[-] 钱包生成失败！${RESET}"
    echo "$SEED_OUTPUT" > "$NCK_DIR/wallet.txt"
    echo -e "[*] 错误输出已保存至 $NCK_DIR/wallet.txt"
    pause_and_return
    return
  fi

  # 将原始输出保存到 walletsony.txt
  echo "$SEED_OUTPUT" > "$NCK_DIR/wallet.txt"
  echo -e "[*] 原始输出已保存至 $NCK_DIR/wallet.txt"

  # 从输出中提取种子短语
  SEED_PHRASE=$(echo "$SEED_OUTPUT" | grep -iE "seed phrase|mnemonic|wallet seed|recovery phrase" | sed 's/.*: //')
  if [ -z "$SEED_PHRASE" ]; then
    echo -e "${RED}[-] 无法提取助记词！${RESET}"
    pause_and_return
    return
  fi
  echo -e "${YELLOW}助记词:${RESET}\n$SEED_PHRASE"

  # 生成主私钥
  MASTER_PRIVKEY=$("$WALLET_CMD" gen-master-privkey --seedphrase "$SEED_PHRASE" | grep -i "master private key" | awk '{print $NF}')
  if [ -z "$MASTER_PRIVKEY" ]; then
    echo -e "${RED}[-] 无法生成主私钥！${RESET}"
    pause_and_return
    return
  fi
  echo -e "${YELLOW}主私钥:${RESET}\n$MASTER_PRIVKEY"

  # 生成主公钥
  MASTER_PUBKEY=$("$WALLET_CMD" gen-master-pubkey --master-privkey "$MASTER_PRIVKEY" | grep -i "master public key" | awk '{print $NF}')
  if [ -z "$MASTER_PUBKEY" ]; then
    echo -e "${RED}[-] 无法生成主公钥！${RESET}"
    pause_and_return
    return
  fi
  echo -e "${YELLOW}主公钥:${RESET}\n$MASTER_PUBKEY"

  # 写入 Makefile
  echo -e "[*] 写入 Makefile 挖矿公钥..."
  sed -i "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $MASTER_PUBKEY|" Makefile
  echo -e "${GREEN}[+] 钱包生成并配置完成。${RESET}"
  
  pause_and_return
}

# ========= 设置挖矿公钥 =========
function configure_mining_key() {
  if [ ! -f "$NCK_DIR/Makefile" ]; then
    echo -e "${RED}[-] 找不到 Makefile，无法设置公钥！${RESET}"
    pause_and_return
    return
  fi

  read -p "[?] 输入你的挖矿公钥 / Enter your mining public key: " key
  sed -i "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $key|" "$NCK_DIR/Makefile"
  echo -e "${GREEN}[+] 挖矿公钥已设置 / Mining key updated.${RESET}"

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
  screen -S leader -dm bash -c "make run-nockchain-leader"
  echo -e "${GREEN}[+] Leader 节点运行中。${RESET}"
  echo -e "${YELLOW}[!] 正在进入日志界面，按 Ctrl+A+D 可退出。${RESET}"
  sleep 2
  screen -r leader
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
  screen -S follower -dm bash -c "make run-nockchain-follower"
  echo -e "${GREEN}[+] Follower 节点运行中。${RESET}"
  echo -e "${YELLOW}[!] 正在进入日志界面，按 Ctrl+A+D 可退出。${RESET}"
  sleep 2
  screen -r follower
  pause_and_return
}

# ========= 查看节点日志 =========
function view_logs() {
  echo ""
  echo "查看节点日志:"
  echo "  1) Leader 节点"
  echo "  2) Follower 节点"
  echo "  0) 返回主菜单"
  echo ""
  read -p "选择查看哪个节点日志: " log_choice
  case "$log_choice" in
    1)
      if screen -list | grep -q "leader"; then
        screen -r leader
      else
        echo -e "${RED}[-] Leader 节点未运行。${RESET}"
      fi
      ;;
    2)
      if screen -list | grep -q "follower"; then
        screen -r follower
      else
        echo -e "${RED}[-] Follower 节点未运行。${RESET}"
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
  echo "  8) 启动 Leader 节点"
  echo "  9) 启动 Follower 节点"
  echo "  10) 查看节点日志"
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
    10) view_logs ;;
    0) echo "已退出。"; exit 0 ;;
    *) echo -e "${RED}[-] 无效选项。${RESET}"; pause_and_return ;;
  esac
}

# ========= 启动主程序 =========
main_menu
