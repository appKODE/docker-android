#!/usr/bin/env bash
# Removes eMudhra (emSign) roots and the Sectigo "AAA Certificate Services" cross-signer
# from the system CA bundle and from every JDK cacerts (CVE-2026-111943/111944, CVE-2026-91403).
# Matches by subject because Ubuntu and Corretto use different aliases.
set -euo pipefail

pattern='emSign|eMudhra|AAA Certificate Services'
storepass=changeit

for bin in openssl keytool update-ca-certificates; do
  command -v "${bin}" >/dev/null || { echo "${bin} is required" >&2; exit 1; }
done

# System bundle: mark matching mozilla certs as deselected and rebuild.
# The ca-certificates-java hook regenerates /etc/ssl/certs/java/cacerts from it.
for crt in /usr/share/ca-certificates/mozilla/*.crt; do
  if openssl x509 -noout -subject -in "${crt}" | grep -Eq "${pattern}"; then
    name="mozilla/$(basename "${crt}")"
    echo "Distrusting ${name}"
    sed -i "s|^${name}\$|!${name}|" /etc/ca-certificates.conf
  fi
done
update-ca-certificates --fresh >/dev/null

java_keystores() {
  {
    [[ -f /etc/ssl/certs/java/cacerts ]] && echo /etc/ssl/certs/java/cacerts
    find /usr/lib/jvm -name cacerts \( -type f -o -type l \) -exec realpath {} \; 2>/dev/null
  } | sort -u
}

matching_aliases() {
  keytool -list -v -keystore "$1" -storepass "${storepass}" 2>/dev/null \
    | awk -v re="${pattern}" '/^Alias name:/ { alias = substr($0, 13) } /^Owner:/ && $0 ~ re { print alias }'
}

while read -r keystore; do
  while read -r alias; do
    [[ -n "${alias}" ]] || continue
    echo "Deleting '${alias}' from ${keystore}"
    keytool -delete -alias "${alias}" -keystore "${keystore}" -storepass "${storepass}"
  done < <(matching_aliases "${keystore}")
done < <(java_keystores)

# Self-check: nothing matching may remain anywhere.
leftovers="$(
  openssl crl2pkcs7 -nocrl -certfile /etc/ssl/certs/ca-certificates.crt \
    | openssl pkcs7 -print_certs -noout | grep -E "${pattern}" || true
)"
while read -r keystore; do
  keytool -list -keystore "${keystore}" -storepass "${storepass}" >/dev/null || leftovers+="unreadable: ${keystore}"$'\n'
  leftovers+="$(matching_aliases "${keystore}" | sed "s|^|${keystore}: |")"
done < <(java_keystores)

if [[ -n "${leftovers}" ]]; then
  echo "Distrusted CAs still present:" >&2
  echo "${leftovers}" >&2
  exit 1
fi
echo "eMudhra/AAA roots removed from system bundle and $(java_keystores | wc -l) JDK keystore(s)"
