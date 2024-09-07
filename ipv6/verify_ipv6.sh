  GNU nano 8.1                                                                            verify_ipv6.sh                                                                                         
#!/bin/sh

status_code=$(curl -I ip6only.me 2>/dev/null | head -n 1 | cut -d$' ' -f2)

if [ "$status_code" == "" ]
then
        logger 'Status ipv6 Down'
        /bin/sh /etc/config_ipv6_with_prefix_delegate.sh
elif [ "$status_code" -eq "200" ]
then
        logger 'Status ipv6 ok'
fi