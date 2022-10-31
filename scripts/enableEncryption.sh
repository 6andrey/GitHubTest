#!/bin/bash
echo "Deploy Permission Set to $1"
sfdx force:source:deploy -p src-access-management/permissionsets/ManageEncryptionKeys.permissionset-meta.xml -u $1

echo "Assign the ManageEncryptionKeys Permission Set to $1"
sfdx force:user:permset:assign -n ManageEncryptionKeys -u $1