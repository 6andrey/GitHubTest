Map<String, SObject> recordsMap(List<SObject> records) {
    Map<String, SObject> m = new Map<String,SObject>();
    for (SObject r: records) {
        m.put(String.valueOf(r.get('Name')), r);
    }
    return m;
}

Map<String, SObject> profilesMap = recordsMap([SELECT Name FROM Profile]);
Map<String, SObject> rolesMap = recordsMap([SELECT Name FROM UserRole]);
Map<String, SObject> permissionsetsMap = recordsMap([SELECT Name FROM PermissionSet]);
//Map<String, SObject> permissionsetgroupsMap = recordsMap([SELECT DeveloperName FROM PermissionSetGroup]);

String resourceName = 'UsersList'; // Replace with the actual name of your Static Resource
String csvBody = '';

// Retrieve the CSV file from the Static Resource
PageReference csvFile = PageReference.forResource(resourceName);
Blob csvBlob;

if (!csvFile.getURL().startsWith('/resource/')) {
    System.debug('Static Resource not found.');
} else {
    csvBlob = csvFile.getContent();
    csvBody = csvBlob.toString();
}

System.debug('csvBody: ' + csvBody);

// Parse and insert user records 

List<User> usersToInsert = new List<User>();

// Split CSV rows by line breaks
List<String> csvRows = csvBody.split('\n');

// Skip the header row (row zero)

for (Integer i = 1; i < csvRows.size(); i++) {
    List<String> csvValues = csvRows[i].split(',');

    List<User> ExistingUser = [SELECT Id FROM User WHERE Username = :csvValues[4]];
    String UsernameString = '';

    if (ExistingUser.isEmpty()) {

        UsernameString = csvValues[4];

    } else {

        UsernameString = csvValues[4] + '.sbx';

    }

    User newUser = new User(
        IsActive = Boolean.valueOf(csvValues[0]),
        FirstName = csvValues[1],
        LastName = csvValues[2],
        Email = csvValues[3],
        Username = UsernameString,
        ProfileId = profilesMap.get(csvValues[5]).Id,
        TimeZoneSidKey = csvValues[6],
        LocaleSidKey = csvValues[7],
        EmailEncodingKey = csvValues[8],
        LanguageLocaleKey = csvValues[9],
        Alias = csvValues[10]
    );

    if (!String.isBlank(csvValues[11])) {

        newUser.UserRoleId = rolesMap.get(csvValues[11]).Id;

    }

    usersToInsert.add(newUser);
}

if (!usersToInsert.isEmpty()) {
    try {
        insert usersToInsert;
        System.debug('Users inserted successfully.');
    } catch (Exception e) {
        System.debug('Error inserting users: ' + e.getMessage());
    }
}

List<PermissionSetAssignment> permissionSetAssignmentsToInsert = new List<PermissionSetAssignment>();

for (Integer i = 1; i < csvRows.size(); i++) {
    List<String> csvValues = csvRows[i].split(',');

    if (!String.isBlank(csvValues[13])) {

        PermissionSetAssignment newPermissionSetAssignment1 = new PermissionSetAssignment (
            AssigneeId = usersToInsert[i-1].Id,
            PermissionSetId = permissionsetsMap.get(csvValues[13]).Id
        );
        permissionSetAssignmentsToInsert.add(newPermissionSetAssignment1);

    }

    if (!String.isBlank(csvValues[14])) {

        PermissionSetAssignment newPermissionSetAssignment2 = new PermissionSetAssignment (
            AssigneeId = usersToInsert[i-1].Id,
            PermissionSetId = permissionsetsMap.get(csvValues[14]).Id
        );
        permissionSetAssignmentsToInsert.add(newPermissionSetAssignment2);

    }

}

if (!permissionSetAssignmentsToInsert.isEmpty()) {
    try {
        insert permissionSetAssignmentsToInsert;
        System.debug('Permission set assignments inserted successfully.');
    } catch (Exception e) {
        System.debug('Error inserting permission set assignments: ' + e.getMessage());
    }
}