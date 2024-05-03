#!/bin/bash
#国家代码（2位大写）
C=CN
#省份区域代码
ST=HeNan
#城市名称
L=ZhengZhhou
#组织名称
O=FreeNet
#组织单位名称
OU=CA
#证书名称
CN=ca.test.com
#服务器证书名称
SERVERCN=test.jackadam.top
#客户端证书名称
CLIENTCN=client.test.com
#管理员邮箱
Email=test@sina.com
#证书时效（年）
year=10

function Create_CA_PEM() {
    if [ ! -d ./CA ]; then
        mkdir CA
    fi

    echo "生成CA私钥"
    openssl genpkey \
        -algorithm ec \
        -pkeyopt ec_paramgen_curve:P-256 \
        -out ./CA/ca.key

    echo "生成CA证书"
    openssl req \
        -new \
        -x509 \
        -days $((365 * year)) \
        -key ./CA/ca.key \
        -out ./CA/ca.crt \
        -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}/emailAddress=${Email}"

    echo "生成CA证书(x509)"
    openssl req \
        -new \
        -x509 \
        -days $((365 * year)) \
        -config ca.conf \
        -key ./CA/ca.key \
        -out ./CA/cax509.crt \
        -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CN}/emailAddress=${Email}"

    echo "证书安全设置"
    echo "设置CA私钥的安全权限"
    chown root:root ./CA/ca.key
    chmod 600 ./CA/ca.key

    echo "备份CA私钥、证书"

    current_datetime=$(date +'%Y-%m-%d_%H:%M:%S')

    cp ./CA/ca.key ./CA/ca_back_${current_datetime}.key
    cp ./CA/ca.crt ./CA/ca_back_${current_datetime}.crt
    cp ./CA/ca.key ./ca_back_${current_datetime}.key
    cp ./CA/ca.crt ./ca_back_${current_datetime}.crt

}

function Create_Server_PEM() {
    if [ ! -d ./certificate ]; then
        mkdir certificate
    fi
    echo "生成server私钥"
    openssl genpkey \
        -algorithm ec \
        -pkeyopt ec_paramgen_curve:P-256 \
        -out ./certificate/server.key

    echo "生成server san 证书请求"
    openssl req \
        -config server.conf \
        -new \
        -key ./certificate/server.key \
        -out ./certificate/server.csr \
        -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CLIENTCN}/emailAddress=${Email}"

    echo "CA 签名server san证书"
    openssl x509 \
        -req \
        -days $((365 * year)) \
        -in ./certificate/server.csr \
        -CA ./CA/ca.crt \
        -CAkey ./CA/ca.key \
        -CAcreateserial \
        -out ./certificate/server.crt \
        -extensions req_ext \
        -extfile server.conf \
        -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${CLIENTCN}/emailAddress=${Email}"

}

function Create_Client_PEM() {
    if [ ! -d ./certificate ]; then
        mkdir certificate
    fi
    echo "生成client私钥"
    openssl genpkey \
        -algorithm ec \
        -pkeyopt ec_paramgen_curve:P-256 \
        -out ./certificate/client.key

    echo "生成client san 证书请求"
    openssl req \
        -new \
        -key ./certificate/client.key \
        -config client.conf \
        -out ./certificate/client.csr

    echo "CA 签名clien san证书"
    openssl x509 \
        -req \
        -days $((365 * year)) \
        -in ./certificate/client.csr \
        -CA ./CA/ca.crt \
        -CAkey ./CA/ca.key \
        -CAcreateserial \
        -out ./certificate/client.crt \
        -extensions client-cert \
        -extfile client.conf \
        -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/OU=${OU}/CN=${SERVERCN}/emailAddress=${Email}"
}

function main() {
    read -p "是否生成CA证书，如果不生成，将使用上次生成的CA证书。直接回车，默认不生成。y/n?:" isCA
    : ${isCA:="n"}
    if [ $isCA = "y" ]; then
        Create_CA_PEM
    fi

    read -p "是否生成服务器证书,直接回车，默认不生成。y/n?" isServer
    : ${isServer:="n"}
    if [ $isServer = "y" ]; then
        Create_Server_PEM
    fi

    read -p "是否生成客户端证书,直接回车，默认不生成。y/n?" isClient
    : ${isClient:="n"}
    if [ $isClient = "y" ]; then
        Create_Client_PEM
    fi
}

main
