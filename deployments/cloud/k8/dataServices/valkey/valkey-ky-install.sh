helm registry login tanzu-valkey.packages.broadcom.com \
   --username=$BROADCOM_MAVEN_USERNAME \
   --password=$BROADCOM_MAVEN_PASSWORD


helm pull oci://tanzu-valkey.packages.broadcom.com/tanzu-valkey-helm --version 1.0.0-beta --untar --untardir /tmp