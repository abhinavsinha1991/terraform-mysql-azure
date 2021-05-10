#HBA sample for ${myprefix}

mysql -u root -p${root-pass} -e "CREATE USER IF NOT EXISTS '${mysql-user-name}'@'%' IDENTIFIED BY '${mysql-user-password}';"
mysql -u root -p${root-pass} -e "GRANT ALL ON dbname.* TO ${mysql-user-name}@'${myip}' IDENTIFIED BY '${mysql-user-password}';"