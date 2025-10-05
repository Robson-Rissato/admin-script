#!/usr/bin/env bash

# block .cf domains for now
#/usr/local/directadmin/scripts/custom/domain_create_pre.sh

# these load up directadmin with too many domains and cause issues due to scaling 
# da rewrite_conf gets too slow dovecot sni is slow
if [[ "$domain" =~ ^.*(\.cf|\.ml|.ga|.tk)$ ]]; then
        echo 'tk ml ga and cf domains from freenom are blocked due to abuse https://krebsonsecurity.com/2023/03/sued-by-meta-freenom-halts-domain-registrations/'
        exit 1;
fi

# phishing protection
if [[ "$domain" =~ ^(interserver\.net|google\.com|gmail\.com|interserver\.com|yahoo\.com|hotmail\.com|outlook\.com|mailbaby\.net|test\.com|mail\.baby|mailbaby\.net)$ ]]; then
	echo 'Invalid domain"';
	exit 1;
fi

# dmca heavy
if [[ "$domain" =~ (kenhtv\.org|motchill1\.pro|phimmoiz2\.net|hdsieunhanh\.net|motphimf\.net|motphim\.us|vkoolz\.com|247phim\.co|247phim\.cc|phimmoif\.net|hdviet\.org|phimmoi\.ru|phimbathu1.pro|phimmoipro3\.net|phimmoivl\.net|bongngotv\.us|dongphimf\.com|phephimz\.com|phimmoichill\.lol|xemphimso\.org|yeuphimmoi\.cc|xemphimso\.pro|rossifirearmsusa\.com|vungtv\.us|tvchill\.net|phimmoiplus\.org|mephimgi\.net|bilutv\.info|hdphimhay\.net|khoaitv\.xyz|phim1080\.pro|chillhayz\.org|chillhayz\.net|bilutvf\.com|asuratoon\.us|knightsgunsusa\.com|filmy4cab\.lat)$ ]]; then
	echo 'Domain is blocked for dmca complaints - please contact support for more info';
	exit 1;
fi

# lastly the file shared between cpanel and directadmin
if [ -f /usr/local/directadmin/scripts/custom/commondomains ]; then
        domcheck=`grep ^${domain}$ /usr/local/directadmin/scripts/custom/commondomains`;
        if [ "$domcheck" = "$domain" ]; then
                echo "Domain is blocked please contact support for more info";
                exit 1;
        fi
fi

exit 0;

