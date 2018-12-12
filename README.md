# Goget Trips

This script fetch the list of fees and charges from the Goget.com.au website.

### Description
It creates two files:
  - **activity_report.csv**

This file contains all of your activity with Goget. (One file is generated with all of the data)
Columns:
| Booking/Transaction ID | Driver Name | Vehicle | Registration | Pod(parking spot) | Trip reason | Booking start | Booking end | Hours booked | Time charge | Km travelled | Km free | Km charge | Damage Cover | Location charge | Fines | Fees | Credits | Tolls | TOTAL(incl GST) | Payment | Total DUE |
--- | --- | --- | --- |--- | --- | --- | --- |--- | --- | --- | --- |--- | --- | --- | --- |--- | --- | --- | --- |--- | --- |

  - **other_fees.csv**

This files contains all of the other fees (ex. Monthly subscription charge). (One file is generated with all of the data)
Columns:

| Date | Type | Summary | Cost(incl GST) |
--- |--- | --- |--- |

### Pre-requisites

This scripts requires **curl** and **jq** to run.

##### MacOS:
```sh
$ brew install curl jq
```
##### Debian / Ubtuntu:
```sh
$ sudo apt-get install curl jq
```

### Parameters

```sh
$ ./Goget.sh -u <User ID> -p <User Password> [-f <Target Folder> -c <Cookie file>]
```
| Parameter | Description | Example |
--- |--- | --- |
User ID | Your Goget user identifier | 12345678 |
User Password |Your Goget user password. If not passed as argument, will ask for user input |  |
Target Folder | The folder you want to save the export to. | ~/GoGet_Files |
Cookie file | Temporary file where to save the cookie file to. This file is deleted once the script finishes | Default: /tmp/cookies_goget |
