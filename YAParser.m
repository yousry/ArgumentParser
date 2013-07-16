//
//  YAParser.m
//
//  Created by Yousry Abdallah.
//  Copyright 2013 yousry.de. All rights reserved.
//  MIT License / see license.txt

#import <Foundation/NSJSONSerialization.h>

#import "YAParser.h"

#define TOKEN_ARGUMENT @"Argument"
#define TOKEN_OPTIONS  @"Options"
#define TOKEN_KEY  @"Key"
#define TOKEN_NAME  @"Name"
#define TOKEN_DOC  @"Doc"
#define TOKEN_UNDEFINED @"UNDEFINED"

#define TAG_UNSET @"UNSET"

#define OPTION_VERSION @"version"
#define OPTION_VERSION_SHORT @"V"
#define OPTION_USAGE @"usage"
#define OPTION_HELP @"help"
#define OPTION_HELP_SHORT @"?"

#define MAX_OPT_PER_LINE 5

static const NSString* TAG = @"YAParser";

@implementation YAParser {
	NSDictionary* argumentDictionary;
	NSString* appName;
	NSArray* parseOptions;
} 

- (id) init;
{
	self = [super init];

	if(self) {
		commandlineArguments = [[NSMutableDictionary alloc] init];
		_versionTag = TAG_UNSET;
		_authorTag = TAG_UNSET;
	}

	return self;
}

- (void) createParseTreeFromFile:(NSString*) jsonFile 
{

NSError *error = nil;

#ifdef __APPLE__	
    NSInputStream* iStream = [[NSInputStream alloc] initWithFileAtPath:jsonFile];
	[iStream open];
	argumentDictionary = [NSJSONSerialization JSONObjectWithStream:iStream options:NSJSONReadingMutableLeaves error:&error];
	[iStream close];
#else // __linux
	NSData* iData = [NSData dataWithContentsOfFile:jsonFile];
    argumentDictionary = [NSJSONSerialization JSONObjectWithData:iData options:NSJSONReadingMutableLeaves error:&error];
#endif

    if(error != nil) {
    	NSLog(@"File not Found: %@", jsonFile);
        return;
    }

	parseOptions = [argumentDictionary objectForKey:TOKEN_OPTIONS];
    appName = NSBundle.mainBundle.bundlePath.lastPathComponent;
} 

-(NSDictionary*) parseCommandLine: (const char**) argv Count: (int) argc;
{
	int (^requestHelp)(NSString*) = ^(NSString* opt) {
		if([opt isEqualToString: OPTION_VERSION] || [opt isEqualToString: OPTION_VERSION_SHORT]) {
			fprintf(stdout, "%s\n", self.versionTag.UTF8String);
			return true;
		} else if([opt isEqualToString: OPTION_USAGE]) {
			fprintf(stdout, "%s\n", self.usageDescription.UTF8String);
			return true;
		} else if([opt isEqualToString: OPTION_HELP] || [opt isEqualToString: OPTION_HELP_SHORT]) {
			fprintf(stdout, "%s\n", self.helpDescription.UTF8String);
			return true;
		} else
			return false;
	};

	NSMutableDictionary* result = [[NSMutableDictionary alloc] init]; 

	for(int i = 1; i < argc; i++) {

		NSString* const opt = [NSString stringWithCString:argv[i] encoding:NSString.defaultCStringEncoding]; 
		NSString* shortOpt = nil;
		NSString* longOpt = nil;

		if([opt hasPrefix:@"--"] && opt.length > 2)
			longOpt = [opt substringFromIndex: 2];
		else if([opt hasPrefix:@"-"] && opt.length > 1)
 			shortOpt = [opt substringFromIndex: 1];
 		else { // The Argument
 			NSDictionary* argument = [argumentDictionary objectForKey:TOKEN_ARGUMENT];
 			if(argument) {
 				NSString* argarg = [argument objectForKey:TOKEN_ARGUMENT];
 				if(argarg)
	 				[result setObject:opt forKey:argarg];
 			}
 		}

		if(shortOpt != nil || longOpt != nil) {
			const bool isShortOpt = shortOpt != nil; 

			const bool needHelp = isShortOpt ? requestHelp(shortOpt) : requestHelp(longOpt);
			if(needHelp)
				return nil;

			for(NSDictionary* parseOption in parseOptions) {
				NSString* const tokenName = [parseOption objectForKey:TOKEN_NAME]; 
				if(( isShortOpt && [ [parseOption objectForKey:TOKEN_KEY] isEqualToString:shortOpt] ) ||
				  ( !isShortOpt && [ tokenName isEqualToString:shortOpt] ) ) {
				 	bool hasArgument = [parseOption objectForKey:TOKEN_ARGUMENT] != nil;
				 	NSString* arg = TOKEN_UNDEFINED;
					if(hasArgument) {
						if(i + 1 >= argc || [ [NSString stringWithCString:argv[i+1]] hasPrefix:@"-"]) {
							fprintf(stderr, "%s: option requires an argument -- %s\n", appName.UTF8String, opt.UTF8String);
							fprintf(stdout, "%s\n", self.helpShortDescription.UTF8String);
							return nil;
						} else
							arg = [NSString stringWithCString:argv[++i] encoding:NSString.defaultCStringEncoding]; 

					}
					[result setObject:arg forKey:tokenName];  
				}
			}
		}
	}

	return (NSDictionary*)[NSDictionary dictionaryWithDictionary: result];
}


-(NSString*) helpShortDescription 
{
	NSDictionary* argument = [argumentDictionary objectForKey:TOKEN_ARGUMENT];
	NSString* argarg =  [argument objectForKey:TOKEN_ARGUMENT]; 

	NSString* usageString = [NSString stringWithFormat:
@"\
Usage: %@ [Option...] %@\n\
Try ` %@ --help' or `%@ --usage' for more information.\
" , appName, argarg, appName, appName]; 
	return usageString;
}

-(NSString*) usageDescription
{
	__block int newLineCounter = 1;
	NSString* (^senseNL)(int) = ^(int tiles) {
		NSString* result = @"";
		newLineCounter++;
		if(!(newLineCounter % tiles))
			result = @"\n\t";
		return result;
	};

	NSString* shortKeys = @"";
    NSMutableArray* optArgs = [[NSMutableArray alloc] init];
    NSMutableArray* optArgsShort = [[NSMutableArray alloc] init];

	for(NSDictionary *parseOption in parseOptions) {


		NSString* optName = [parseOption objectForKey: TOKEN_NAME];
		NSString* optArgument = [parseOption objectForKey: TOKEN_ARGUMENT];
		NSString* optKey = [parseOption objectForKey: TOKEN_KEY];

		NSString* optArgString = nil;
		NSString* optArgShortString = nil;

		if(optArgument == nil) {
			shortKeys = [NSString stringWithFormat:@"%@%@", shortKeys, optKey]; // concat
			optArgString = [NSString stringWithFormat:@"[--%@]", optName];
		} else {
			optArgString = [NSString stringWithFormat:@"[--%@=%@]", optName, optArgument];
			optArgShortString = [NSString stringWithFormat:@"[-%@ %@]", optKey, optArgument];
			[optArgsShort addObject: optArgShortString];
		}
		[optArgs addObject: optArgString];
	}

	NSString* result = [NSString stringWithFormat:@"Usage: %@",appName]; // concat
	result = [NSString stringWithFormat:@"%@ [-%@u\?v]", result , shortKeys];
	

	for(NSString* optArgShort in optArgsShort) 
		result = [NSString stringWithFormat:@"%@ %@", result, optArgShort, senseNL(MAX_OPT_PER_LINE)];

	for(NSString* optArg in optArgs) {
				result = [NSString stringWithFormat:@"%@ %@", result, optArg, senseNL(MAX_OPT_PER_LINE)];
	}

	return result;
} 

-(NSString*) helpDescription 
{
	NSString* result = self.usageDescription;
	result = [NSString stringWithFormat:@"%@\n%@\n", result, [argumentDictionary objectForKey:TOKEN_DOC] ];

	for(NSDictionary* parseOption in  parseOptions) {
		NSString* optName = [parseOption objectForKey: TOKEN_NAME];
		NSString* optArgument = [parseOption objectForKey: TOKEN_ARGUMENT];
		NSString* optKey = [parseOption objectForKey: TOKEN_KEY];
		NSString* optDoc = [parseOption objectForKey: TOKEN_DOC];

		NSString* lineResult = [NSString stringWithFormat:@"\n  -%@, --%@", optKey, optName]; // concat

		if(optArgument!=nil)		
			lineResult = [NSString stringWithFormat:@"%@=%@", lineResult, optArgument];

		lineResult = [lineResult stringByPaddingToLength: 30 withString:@" " startingAtIndex:0];

		result = [result stringByAppendingString:lineResult];
		result = [result stringByAppendingString:optDoc];
	}

	result = [NSString stringWithFormat:@"%@\n  -?, --help                 Give this help list", result];
	result = [NSString stringWithFormat:@"%@\n      --usage                Give a short usage message", result];
	result = [NSString stringWithFormat:@"%@\n  -V, --version              Print program version", result];

	result = [result stringByAppendingString:
		@"\n\nMandatory or optional arguments to long options are also mandatory or optional\nfor any corresponding short options.\n\n"];

	result = [result stringByAppendingString:_authorTag];
	return result;
}	


@end