# DropCheck for Linux

Mac向けのオリジナルのDropCheckスクリプトが期待通りに動作しなかったため、Linux環境向けに再実装および機能拡張を行ったものです。
ネットワークの基本的な接続性診断を自動化し、その結果をログに記録します。

## ファイル構成 (主要スクリプト)

```text
├── Launch-Dropcheck.sh       # メイン実行スクリプト
├── dropcheck.conf            # 設定ファイル (診断ターゲット等を記述)
├── Initial-Setup.sh          # 事前設定・環境情報表示スクリプト
├── Ping-test.sh              # Pingテスト実行スクリプト
├── Traceroute-test.sh        # Tracerouteテスト実行スクリプト
├── DNS-LookUp.sh             # DNSルックアップテスト実行スクリプト
├── HTTP-Request-Test.sh      # HTTPリクエストテスト実行スクリプト
├── Firewall-Check.sh         # ファイアウォールテスト実行スクリプト
├── MTR-From-Hostlist.sh      # hostlist.txt を利用したMTRテスト実行スクリプト (Launch-Dropcheckからは現在呼び出されません)
├── Trace-DNS.sh              # hostlistを利用したTraceroute結果の名前解決スクリプト (Launch-Dropcheckからは呼び出されません)
├── hostlist.txt              # MTR-From-Hostlist.sh や Trace-DNS.sh が参照するホストリストのサンプル
└── README.md                 # このファイル

```

## 必要なツール (Requirements)

本ツール群を実行するには、以下のコマンドラインツールがシステムにインストールされている必要があります。

- `ping`, `ping6` (通常 `iputils-ping` パッケージに含まれます)
- `traceroute`
- `dig` (通常 `dnsutils` または `bind-utils` パッケージに含まれます)
- `curl`
- `ip` (通常 `iproute2` パッケージに含まれます)
- `nmcli` (`Initial-Setup.sh` で使用。NetworkManager環境が必要です)
- `mtr`
  (MTRテストを実行する場合に必要です。`MTR-test.sh` や `test-mtr.sh` で使用します)
- `sudo` (多くの診断スクリプト、特に `Initial-Setup.sh` でシステム設定の変更や特権コマンドの実行に必要です)

お使いのディストリビューションのパッケージマネージャを利用してインストールしてください。
Ubuntu/Debian系の例: `sudo apt install iputils-ping traceroute mtr dnsutils curl iproute2 network-manager`
スクリプトに実行権限を付与してください: `chmod +x *.sh`

## 使用方法 (Usage)

メインスクリプト `Launch-Dropcheck.sh` を実行することで、設定ファイルに基づいた一連の診断スクリプトが自動的に実行されます。

```bash
# Initial-Setup.sh などがシステム操作を行うため、sudo を使用して実行することを推奨します。
# スクリプトに実行権限が付与されていることを確認してください (例: chmod +x Launch-Dropcheck.sh)。
$ sudo ./Launch-Dropcheck.sh -o <ログファイル名> -i <インターフェース名> -c <設定ファイル名>

```

**オプション:**

- `-o, --output <ログファイル名>`: 診断結果を保存するログファイルのパスを指定します。
- `-i, --interface <インターフェース名>`: PingテストやTracerouteテストで使用するネットワークインターフェースを指定します (例: `eth0`)。
- `-c, --config <設定ファイル名>`: 診断ターゲットのIPアドレスやドメイン名などが記述された設定ファイルを指定します (例: `dropcheck.conf`)。

**実行例:**

```bash
$ sudo ./Launch-Dropcheck.sh -o dropcheck_results.log -i eth0 -c dropcheck.conf
```

`Launch-Dropcheck.sh` は各サブスクリプトを呼び出すキックスクリプトです。
個別の診断のみを実行したい場合は、各サブスクリプト（例: `Ping-test.sh`）を直接実行することも可能です。その際は、各スクリプトが必要とするオプションを確認してください（通常 `-h` または `--help` で確認できます）。

## 設定ファイル (dropcheck.conf)

`dropcheck.conf` ファイルには、各診断スクリプトが使用するターゲットIPアドレス、ドメイン名、URLなどをキーと値のペアで記述します。
このファイルを編集することで、スクリプト本体を変更せずに診断対象をカスタマイズできます。
提供されている `dropcheck.conf` を参考に、環境に合わせて値を変更してください。

## 注意事項 (Notes)

- `Initial-Setup.sh` は `nmcli` を使用してインターフェースの再起動を試みるため、NetworkManagerが管理している環境での実行を想定しています。また、DNSキャッシュクリアのロジックも特定のサービスに依存しています。
- `Traceroute-test.sh`, `MTR-test.sh`, `test-mtr.sh` および `Initial-Setup.sh` の一部機能は `sudo` 権限を必要とします。
- `hostlist.txt` は、`test-mtr.sh` や `Trace-DNS.sh` のようなスタンドアロンの補助スクリプトで使用されることを想定した、IPアドレスとホスト名の対応リストのサンプルです。`Launch-Dropcheck.sh` から実行される主要な診断フローでは直接使用されません。
