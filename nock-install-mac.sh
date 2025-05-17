#!/bin/bash

set -e

echo -e "\n🍺 安装依赖工具（通过 Homebrew）..."
# 检查并安装 Homebrew
if ! command -v brew &> /dev/null; then
  echo "⚠️ 未检测到 Homebrew，正在安装..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update
brew install git curl wget jq lz4 make gcc automake autoconf tmux htop pkg-config openssl leveldb coreutils gnu-sed screen

echo -e "\n🦀 安装 Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup default stable

echo -e "\n📁 检查 nockchain 仓库..."
if [ -d "nockchain" ]; then
  echo "⚠️ 已存在 nockchain 目录，是否删除重新克隆（必须选 y ）？(y/n)"
  read -r confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    rm -rf nockchain
    git clone https://github.com/zorp-corp/nockchain
  else
    echo "➡️ 使用已有目录 nockchain"
  fi
else
  git clone https://github.com/zorp-corp/nockchain
fi

cd nockchain

echo -e "\n🔧 编译核心组件中..."
make install-hoonc
make build
make install-nockchain-wallet
make install-nockchain

echo -e "\n✅ 配置环境变量..."
ENV_FILE="$HOME/.zprofile"
echo 'export PATH="$PATH:/root/nockchain/target/release"' >> "$ENV_FILE"
echo 'export RUST_LOG=info' >> "$ENV_FILE"
echo 'export MINIMAL_LOG_FORMAT=true' >> "$ENV_FILE"
source "$ENV_FILE"

# === 生成钱包 ===
echo -e "\n🔐 自动生成钱包助记词与主私钥..."
WALLET_CMD="./target/release/nockchain-wallet"
if [ ! -f "$WALLET_CMD" ]; then
  echo "❌ 未找到钱包命令 $WALLET_CMD"
  exit 1
fi

SEED_OUTPUT=$($WALLET_CMD keygen)
echo "$SEED_OUTPUT"

SEED_PHRASE=$(echo "$SEED_OUTPUT" | grep -iE "seed phrase" | sed 's/.*: //')
echo -e "\n🧠 助记词：$SEED_PHRASE"

echo -e "\n🔑 从助记词派生主私钥..."
MASTER_PRIVKEY=$($WALLET_CMD gen-master-privkey --seedphrase "$SEED_PHRASE" | grep -i "master private key" | awk '{print $NF}')
echo "主私钥：$MASTER_PRIVKEY"

echo -e "\n📬 获取主公钥..."
MASTER_PUBKEY=$($WALLET_CMD gen-master-pubkey --master-privkey "$MASTER_PRIVKEY" | grep -i "master public key" | awk '{print $NF}')
echo "主公钥：$MASTER_PUBKEY"

echo -e "\n📄 写入 Makefile 挖矿公钥..."
gsed -i "s|^export MINING_PUBKEY :=.*$|export MINING_PUBKEY := $MASTER_PUBKEY|" Makefile

# === 可选：初始化 choo hoon 测试 ===
read -p $'\n🌀 是否执行 choo 初始化测试？这一步可能卡住界面，非必须操作。输入 y 继续：' confirm_choo
if [[ "$confirm_choo" == "y" || "$confirm_choo" == "Y" ]]; then
  mkdir -p hoon assets
  echo "%trivial" > hoon/trivial.hoon
  choo --new --arbitrary hoon/trivial.hoon
fi

# === 启动指引 ===
echo -e "\n🚀 配置完成，启动命令如下："

echo -e "\n➡️ 启动 leader 节点："
echo -e "screen -S leader\nmake run-nockchain-leader"

echo -e "\n➡️ 启动 follower 节点："
echo -e "screen -S follower\nmake run-nockchain-follower"

echo -e "\n📄 查看日志方法："
echo -e "screen -r leader   # 查看 leader 日志"
echo -e "screen -r follower # 查看 follower 日志"
echo -e "按 Ctrl+A 再按 D 可退出 screen 会话"

echo -e "\n🎉 部署完成，祝你挖矿愉快！"
