//
//  YAParser.h
//
//  Created by Yousry Abdallah.
//  Copyright 2013 yousry.de.
//  MIT License / see LICENSE

#import <Foundation/Foundation.h>

@interface YAParser: NSObject 

@property (strong, readwrite) NSString* versionTag;
@property (strong, readwrite) NSString* authorTag;

@property (strong, readonly) NSDictionary* parseTree;

- (id) init;
-(void) createParseTreeFromFile:(NSString*) jsonFile;
-(void) createParseTreeFromString:(NSString*) jsonString;


-(NSString*) helpShortDescription;
-(NSString*) usageDescription;
-(NSString*) helpDescription;

-(NSDictionary*) parseCommandLine: (const char**) argv Count: (int) argc;

@end