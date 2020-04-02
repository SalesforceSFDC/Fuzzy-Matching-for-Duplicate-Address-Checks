# Fuzzy-Matching-for-Duplicate-Address-Checks
* https://salesforce.stackexchange.com/questions/9619/fuzzy-matching-for-duplicate-address-checks?newreg=ec3ab7e0f5de47428d8bfc2bb7fe9557
## Helper Functions
```java
// Convert nulls to empty strings
private static string ops(string s) {
    return s == null?'':s;
}

```
## Find Accounts Matching Address
```java
/**
  * Return all accounts matching this address
  *  The field AnnualRevenue is misused to return the probability of match
  */
public static List<Account> AccountsByAddress(String Name1, String Street, String Postcode, String City, String Country) {

    List<Account> result = new List<Account>();

    List<Account> accs;
    Integer MAX = 50;

    // Find accounts with same postcode OR city
    accs = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, BillingCountry
            FROM Account
            WHERE BillingCountry = :Country AND (BillingPostalCode = :Postcode OR BillingCity = :City)
            LIMIT :MAX];
    if (accs.size() == MAX) {
        // Too many, enforce same postcode
        accs = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, BillingCountry
                FROM Account
                WHERE BillingCountry = :Country AND BillingPostalCode = :Postcode
                LIMIT :MAX];
    }
    if (accs.size() == 0) {
        // None, try same city
        system.debug('Fuzzy pre-selected none!');
        accs = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, BillingCountry
            FROM Account
            WHERE BillingCountry = :Country AND BillingCity = :City
            LIMIT :MAX];
    } else if (accs.size() == MAX) {
        // Too many, enforce city
        system.debug('Fuzzy postcode pre-selected too many!');
        accs = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, BillingCountry
                          FROM Account
                          WHERE BillingCountry = :Country AND BillingPostalCode = :Postcode AND BillingCity = :City
                          LIMIT :MAX];
    }
    system.debug('Fuzzy accounts Pre-selected '+accs.size());

    if (accs.size() == MAX) {
        // Too many, enforce name
        system.debug('Fuzzy postcode and city pre-selected too many(2)!');
        string Name4 = Name1.substring(0, 4)+'%';
        accs = [SELECT Id, Name, BillingStreet, BillingPostalCode, BillingCity, BillingCountry
                          FROM Account
                          WHERE BillingCountry = :Country AND BillingPostalCode = :Postcode AND BillingCity = :City
                            AND Name LIKE :Name4
                          LIMIT :MAX];
    }
    system.debug('Fuzzy accounts pre-selected '+accs.size());

    String Name10   = phonetic(Name1, 10);
    String Street10 = phonetic(Street, 10);
    String City10   = phonetic(City, 10);
    system.debug('Name10='+Name10+', Street10='+Street10+', City10='+City10);

    String Name4   = phonetic(Name1, 4);
    String Street4 = phonetic(Street, 4);
    String City4   = phonetic(City, 4);
    system.debug('Name4='+Name4+', Street4='+Street4+', City4='+City4);

    for (Account acc: accs) {
        system.debug(acc);
        Boolean SameName     = (acc.Name == Name1);
        // SF Street is multi-line, if SAP Street is in there somewhere it's a match
        Boolean SameStreet   = (acc.BillingStreet == Street || ops(acc.BillingStreet).indexOf(Street)>=0);
        Boolean SameCity     = (acc.BillingCity == City);
        Boolean SamePostcode = (acc.BillingPostalCode == Postcode);
        system.debug('SameName='+SameName+', SameStreet='+SameStreet+', SameCity='+SameCity+', SamePostcode='+SamePostcode);

        Boolean Like10Name   = (phonetic(acc.Name, 10) == Name10);
        Boolean Like10Street = (phonetic(acc.BillingStreet, 10) == Street10);
        Boolean Like10City   = (phonetic(acc.BillingCity, 10) == City10);
        system.debug('Like10Name='+Like10Name+', Like10Street='+Like10Street+', Like10City='+Like10City);

        Boolean Like4Name   = (phonetic(acc.Name, 4) == Name4);
        Boolean Like4Street = (phonetic(acc.BillingStreet, 4) == Street4);
        Boolean Like4City   = (phonetic(acc.BillingCity, 4) == City4);
        system.debug('Like4Name='+Like4Name+', Like4Street='+Like4Street+', Like4City='+Like4City);

        if (SameName && SameStreet && SameCity && SamePostcode)
          acc.AnnualRevenue = 99;
        else if (SameName && SameStreet && SameCity) acc.AnnualRevenue = 98;
        else if (SameName && SameStreet && ( SameCity || SamePostcode )) acc.AnnualRevenue = 97;
        else if (SameName && Like10Street && SameCity && SamePostcode)   acc.AnnualRevenue = 96;
        else if (Like10Name && SameStreet && SameCity)            acc.AnnualRevenue = 95;
        else if (SameName && SameCity && SamePostcode)            acc.AnnualRevenue = 94;
        else if (SameName && SameStreet && Like10City)            acc.AnnualRevenue = 94;
        else if (SameName && Like10Street && Like10City)          acc.AnnualRevenue = 93;
        else if (Like10Name && SameStreet && Like10City)          acc.AnnualRevenue = 92;
        else if (Like10Name && Like10Street && SameCity)          acc.AnnualRevenue = 91;
        else if (Like10Name && Like10Street && Like10City)        acc.AnnualRevenue = 90;
        else if (SameName && Like4Street && SameCity)             acc.AnnualRevenue = 86;
        else if (Like4Name && SameStreet && SameCity)             acc.AnnualRevenue = 85;
        else if (SameName && SameStreet && Like4City)             acc.AnnualRevenue = 84;
        else if (SameName && Like4Street && Like4City)            acc.AnnualRevenue = 83;
        else if (Like4Name && SameStreet && Like4City)            acc.AnnualRevenue = 82;
        else if (Like4Name && Like4Street && SameCity)            acc.AnnualRevenue = 81;
        else if (Like4Name && Like4Street && Like4City)           acc.AnnualRevenue = 80;
        else if (SamePostcode && Like4City && Like10Name && country != 'China' && country != 'Korea' && country != 'Japan')
          // Same postcode, similar city(4), similar name(10)
          acc.AnnualRevenue = 80;
        else if (SameName && SameCity)
          // Different postcode, same name, same city (postcode misspelled)
          acc.AnnualRevenue = 80;
        else if (SameCity && SameStreet)
          // Same postcode, city && street - name might be misspelled
          acc.AnnualRevenue = 79;
        else if (SameName && SameStreet)              acc.AnnualRevenue = 74;
        else if (Like4Name && Like4Street)            acc.AnnualRevenue = 73;
        else if (Like4Street && SameCity)             acc.AnnualRevenue = 72;
        else if (Like4Name && Like4City)              acc.AnnualRevenue = 71;
        else {
          // Probably not a duplicate
          system.debug('PROB=0');
          continue;
        }
        system.debug('PROB='+acc.AnnualRevenue);

        result.add(acc);
    }

    return result;
}
```
## Use Case
```apex
// Check account newAcc against all Accounts
Account[] accs = Fuzzy.AccountsByAddress(
                   newAcc.Name,
                   ,newAcc.BillingStreet
                   ,newAcc.BillingPostalCode
                   ,newAcc.BillingCity
                   ,newAcc.BillingCountry
                 );
```
