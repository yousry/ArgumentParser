//
//  main.m
//  ParserExample
//
//  Created by Yousry Abdallah on 20.04.15.
//  Copyright (c) 2013-15 Yousry Abdallah. All rights reserved.
//

#include <iostream>
#include <map>
#include "FUParser.h"

using namespace util;
using namespace std;

#import <Foundation/Foundation.h>
#import "YAParser.h"

#define VERSION_TAG @"VERSION 0.42"
#define AUTHOR_TAG @"Report bugs to <GrouchoM@example.com> "

#define VERSION_TAG_C "VERSION 0.42"
#define AUTHOR_TAG_C "Report bugs to <GrouchoM@example.com> "

//#define USE_OBJC
#define USE_CXX

int main(int argc, const char * argv[])
{

#ifdef USE_OBJC
    @autoreleasepool {
        YAParser* parser = [[YAParser alloc] init];
        
        // Set version and author information
        parser.versionTag = VERSION_TAG;
        parser.authorTag = AUTHOR_TAG;
        
        // Example of a json argument grammar
        [parser createParseTreeFromString:@"{\"Doc\":\"ParserExample -- Demonstration of parser class.\",\"Argument\":{\"Argument\":\"INPUT\",\"Doc\":\"A short Description\"},\"Options\":[{\"Name\":\"outfile\",\"Key\":\"o\",\"Argument\":\"OUTFILE\",\"Doc\":\"Resulting output\"},{\"Name\":\"myarg\",\"Key\":\"m\",\"Argument\":\"ARGUE\",\"Doc\":\"Option with argument.\"},{\"Name\":\"without\",\"Key\":\"w\",\"Doc\":\"Option without argument.\"}]}"];

        // Example of a json argument grammar
        NSDictionary* options = [parser parseCommandLine: argv Count: argc ];
        
        for(NSString *key in options.allKeys)
            NSLog(@"Parsed  Option: %@ Argument: %@", key, [options objectForKey:key]);
    }
#endif

#ifdef USE_CXX
    FUParser parser;

    // Set version and author information
    parser.setVersionTag(VERSION_TAG_C);
    parser.setAuthorTag(AUTHOR_TAG_C);

    // A stringyfied argument grammar
    parser.createParseTreeFromString("{\"Doc\":\"ParserExample -- Demonstration of parser class.\",\"Argument\":{\"Argument\":\"INPUT\",\"Doc\":\"A short Description\"},\"Options\":[{\"Name\":\"outfile\",\"Key\":\"o\",\"Argument\":\"OUTFILE\",\"Doc\":\"Resulting output\"},{\"Name\":\"myarg\",\"Key\":\"m\",\"Argument\":\"ARGUE\",\"Doc\":\"Option with argument.\"},{\"Name\":\"without\",\"Key\":\"w\",\"Doc\":\"Option without argument.\"}]}");
    
    auto options = parser.parseCommandLine(argv, argc);

    for(auto it = options.begin(); it != options.end(); ++it)
    {
        cout << "Parsed Option: " << it->first << " Argument: " << it->second;
    }
#endif
    
    return 0;
}

