//
//  main.m
//  ParserExample
//
//  Created by Yousry Abdallah on 16.07.13.
//  Copyright (c) 2013 Yousry Abdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YAParser.h"

#define VERSION_TAG @"VERSION 0.42"
#define AUTHOR_TAG @"Report bugs to <GrouchoM@example.com> "


int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        YAParser* parser = [[YAParser alloc] init];
        
        // Set version and author information
        parser.versionTag = VERSION_TAG;
        parser.authorTag = AUTHOR_TAG;
        
        // A stringyfied json parser
        [parser createParseTreeFromString:@"{\"Doc\":\"ParserExample -- Demonstration of parser class.\",\"Argument\":{\"Argument\":\"INPUT\",\"Doc\":\"A short Description\"},\"Options\":[{\"Name\":\"outfile\",\"Key\":\"o\",\"Argument\":\"OUTFILE\",\"Doc\":\"Resulting output\"},{\"Name\":\"myarg\",\"Key\":\"m\",\"Argument\":\"ARGUE\",\"Doc\":\"Option with argument.\"},{\"Name\":\"without\",\"Key\":\"w\",\"Doc\":\"Option without argument.\"}]}"];

        // Parse the options
        NSDictionary* options = [parser parseCommandLine: argv Count: argc ];
        
        for(NSString *key in options.allKeys)
            NSLog(@"Parsed  Option:%@ Argument: %@", key, [options objectForKey:key]);
        
    
    }
    return 0;
}

