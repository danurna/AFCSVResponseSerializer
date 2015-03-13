/*
 * AFCSVResponseSerializer.h
 *
 * Copyright (c) 2015 Daniel Witurna.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "AFCSVResponseSerializer.h"
#import "CHCSVParser.h"

#define DEFAULT_DELIMITER ','

@interface AFCSVResponseSerializer () <CHCSVParserDelegate>

@property (readwrite, nonatomic, strong) dispatch_semaphore_t semaphore;
@property (readwrite, nonatomic, assign) unichar delimiter;

@property (readwrite, nonatomic, strong) id responseCSV;
@property (readwrite, nonatomic, strong) NSMutableArray *currentLine;
@property (readwrite, nonatomic, strong) NSError *CSVError;

@end

@implementation AFCSVResponseSerializer

+ (instancetype)serializer {
    return [self serializerWithDelimiter:DEFAULT_DELIMITER];
}

+ (instancetype)serializerWithDelimiter:(unichar)delimiter{
    AFCSVResponseSerializer *serializer = [[self alloc] init];
    serializer.delimiter = delimiter;
    return serializer;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.semaphore = dispatch_semaphore_create(0);
        self.acceptableContentTypes = [NSSet setWithObjects:@"text/csv", nil];
        self.delimiter = DEFAULT_DELIMITER;
    }
    
    return self;
}

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error{

    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]){
        return nil;
    }
    
    // Prepare data and reset error
    NSString *responseString = [NSString stringWithUTF8String:[data bytes]];
    self.CSVError = nil;
    
    // Start parsing
    CHCSVParser *parser = [[CHCSVParser alloc] initWithDelimitedString:responseString delimiter:self.delimiter];
    parser.delegate = self;
    parser.sanitizesFields = YES;
    [parser parse];
    
    // Wait for parsing to finish
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    // Forward parser errors
    *error = self.CSVError;
    
    return _responseCSV;
}

#pragma mark - CHCSVParserDelegate

- (void)parserDidBeginDocument:(CHCSVParser *)parser
{
    self.responseCSV = [NSMutableArray new];
}

- (void)parserDidEndDocument:(CHCSVParser *)parser{
    dispatch_semaphore_signal(self.semaphore);
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber
{
    self.currentLine = [NSMutableArray new];
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber
{
    [self.responseCSV addObject:self.currentLine];
    self.currentLine = nil;
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex
{
    [self.currentLine addObject:field];
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error
{
    self.responseCSV = nil;
    self.CSVError = error;
    dispatch_semaphore_signal(self.semaphore);
}

@end
