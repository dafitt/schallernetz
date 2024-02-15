# [orther/dotnix](https://github.com/orther/dotnix/blob/1cef8dd7513a635c9763d9658330ab714911c0c0/config/services/dns/podman-pihole.nix#L117)
# [jkachmar/termina](https://github.com/jkachmar/termina/blob/b1acee07568544e865c859ef5053f89b868d063d/modules/nixos/services/pihole.nix)
# [mads256h/nixos-server](https://github.com/mads256h/nixos-server/blob/e3c4eb4cccf1843ae2fc559d4a0ce7f2bb915bfe/pihole.nix)

# A network wide black hole for Internet advertisements

{ config, lib, pkgs, ... }: {

  imports = [ ./podman.nix ];

  virtualisation.oci-containers.containers."pihole" = {
    autoStart = true;

    image = "docker.io/pihole/pihole:latest";
    workdir = "/etc/pihole";
    volumes = [
      "/etc/pihole/pihole:/etc/pihole/"
      "/etc/pihole/dnsmasq.d:/etc/dnsmasq.d/"
    ];
    extraOptions = [
      "--network=ipvlan"
      "--ip=***REMOVED_IPv4***"
      "--ip6=***REMOVED_IPv6***"
    ];

    # https://github.com/pi-hole/docker-pi-hole/#environment-variables
    environment = {
      PIHOLE_DNS_ = "***REMOVED_IPv4***;***REMOVED_IPv6***";
      TZ = config.time.timeZone;
      # TODO sops
      WEBPASSWORD = "pi";
      #WEBPASSWORD_FILE =
      WEBTHEME = "default-light";
      FTLCONF_LOCAL_IPV4 = "***REMOVED_IPv4***";
      # Enable DNS conditional forwarding for device name resolution
      REV_SERVER = "true";
      REV_SERVER_DOMAIN = "fritz.box";
      REV_SERVER_TARGET = "***REMOVED_IPv4***"; # Router IP.
      REV_SERVER_CIDR = "***REMOVED_IPv4***/23";
      # Hostname/IP allows you to make changes in addition to the default 'http://.../admin/'
      VIRTUAL_HOST = "pihole.${config.networking.domain}";
    };
  };

  systemd.services.podman-pihole =
    let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in
    {
      after = [ "network.target" ];
      #wants = [ "dnscrypt-proxy2.service" ];
      #wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p /etc/pihole/pihole
        mkdir -p /etc/pihole/dnsmasq.d
        #${dockerBin} pull ${config.virtualisation.oci-containers.containers."pihole".image}
      '';

      #postStart =
      #  lib.mkMerge [
      #    # Wait for the container to start.
      #    ''
      #      while ! ${dockerBin} ps | grep pihole; do
      #        sleep 10s
      #        echo "Waiting on container"
      #      done
      #      sleep 30s
      #    ''
      #    # Add adlists
      #    (builtins.foldl' (x: y: x + "${dockerBin} exec pihole pihole -a adlist add \"" + y + "\"\n") ""
      #      [
      #        "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
      #        "https://adaway.org/hosts.txt"
      #        "https://v.firebog.net/hosts/AdguardDNS.txt"
      #        "https://v.firebog.net/hosts/Admiral.txt"
      #        "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
      #        "https://v.firebog.net/hosts/Easylist.txt"
      #        "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
      #        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
      #        "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
      #        "https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts"
      #        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
      #        "https://v.firebog.net/hosts/static/w3kbl.txt"
      #        "https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt"
      #        "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
      #        "https://someonewhocares.org/hosts/zero/hosts"
      #        "https://raw.githubusercontent.com/HorusTeknoloji/TR-PhishingList/master/url-lists.txt"
      #        "https://v.firebog.net/hosts/Easyprivacy.txt"
      #        "https://v.firebog.net/hosts/Prigent-Ads.txt"
      #        "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt"
      #        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
      #        "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
      #        "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
      #        "https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt"
      #        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt"
      #        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
      #        "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt"
      #        "https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt"
      #        "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
      #        "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
      #        "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
      #        "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
      #        "https://phishing.army/download/phishing_army_blocklist_extended.txt"
      #        "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
      #        "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
      #        "https://urlhaus.abuse.ch/downloads/hostfile/"
      #        "https://v.firebog.net/hosts/Prigent-Malware.txt"
      #        "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn/hosts"
      #        "https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_all.list"
      #        "https://v.firebog.net/hosts/Prigent-Crypto.txt"
      #        "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"
      #      ])
      #    # Add regexes
      #    (builtins.foldl' (x: y: x + "${dockerBin} exec pihole pihole --regex '" + y + "'\n") ""
      #      [
      #        "\\.asia$"
      #        "\\.cn$"
      #        "(\\.|^)huawei\\.com$"
      #        "(\\.|^)open-telekom-cloud\\.com$"
      #        "dbank"
      #        "hicloud"
      #      ])
      #    # Add blacklisted domains
      #    (builtins.foldl' (x: y: x + "${dockerBin} exec pihole pihole -b \"" + y + "\"\n") ""
      #      [
      #        "dubaid.co.uk"
      #      ])
      #    # Add whitelisted domains
      #    (builtins.foldl' (x: y: x + "${dockerBin} exec pihole pihole -w \"" + y + "\"\n") ""
      #      [
      #        "connectivitycheck.cbg-app.huawei.com"
      #        "connectivitycheck.platform.hicloud.com"
      #        "fonts.gstatic.com"
      #        "4chan.org"
      #        "boards.4channel.org"
      #        "boards.4chan.org"
      #      ])
      #    # Apply changes
      #    "${dockerBin} exec pihole pihole -g"
      #  ];
    };
}
