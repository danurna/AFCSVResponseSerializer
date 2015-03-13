AFCSVResponseSerializer
=====================

AFCSVResponseSerializer is a serializer for [AFNetworking](https://github.com/AFNetworking/AFNetworking/) that parses CSV-responses using [CHCSVParser](https://github.com/davedelong/CHCSVParser). The parsing part is mostly taken from [AFCSVRequestOperation](https://github.com/acerbetti/AFCSVRequestOperation) which is not working anymore in newer AFNetworking versions. 

Example Usage
------------------

``` objective-c
AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
manager.responseSerializer = [AFCSVResponseSerializer serializer];
[manager GET:@"http://data.wien.gv.at/csv/wienerlinien-ogd-steige.csv" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"CSV Data as array: %@", responseObject);
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
}];

```

License
------------------
AFCSVResponseSerializer is available under the MIT license. See the LICENSE file for more information.