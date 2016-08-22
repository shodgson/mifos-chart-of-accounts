# Mifos chart of accounts import tool
Bash script to import a Mifos X chart of accounts from a CSV file

#### Usage
./importCoA.sh -u [MifosUsername] -p [MifosPassword] -t [MifosTenantId] -a [MifosUrl] -f [CSV file]
Example:
````shell
./importCoA.sh -u mifos -p password -t default -a https://domain.com:8443/fineract-provider/ -f sampleCoA.csv
````

#### CSV format
(See sampleCoA.csv for an example template)
* One row of field headers
* Columns must be:
  * ID (integer): sequential from 1 (note: the resourceId will be set automatically)
  * ParentId (integer): a number that corresponds to the ID above
  * name (string): account name
  * glCode (string): A user defined identifier to define the account. Must be unique.
  * manualEntriesAllowed (boolean): define whether users can make manual entries
  * TypeValue (string): ASSET, LIABILITY, EQUITY, INCOME, or EXPENSE
  * usage (string): DETAIL or HEADER
  * description (string): An informative description about the account
  
#### Restrictions
  * Data must not have any commas other than seperators
  
#### Compatibility
* Linux (tested)
* Mac with Bash 4 (untested)
* Windows with Cygwin (untested)

Author:  Steven Hodgson

Contact: steven@kanopi.asia
 
