//
//  FUParser.h
//  ParserExample
//
//  Created by Yousry Abdallah on 22.04.15.
//  Copyright (c) 2015 Yousry Abdallah. All rights reserved.
//

#ifndef __ParserExample__FUParser__
#define __ParserExample__FUParser__

#include <vector>
#include <map>
#include <string>
#include <stdio.h>
#include <json/value.h>

namespace util {

 
    class FUParser {

        
    private:

        std::string _versionTag;
        std::string _authorTag;
        std::map<std::string, std::string> _parseTree;
        
        void defaultOptions();

        
        Json::Value argumentDictionary;
        std::string appName;
        Json::Value parseOptions;
        
    public:
        
        std::string getVersionTag();
        void setVersionTag(std::string);

        std::string getAuthorTag();
        void setAuthorTag(std::string);

        std::map<std::string, std::string> getparseTree();
        
        FUParser();
        ~FUParser();
        
        void createParseTreeFromFile(std::string jsonFile);
        void createParseTreeFromString(std::string jsonString);
        
        std::string helpShortDescription();
        std::string usageDescription();
        std::string helpDescription();

        std::map<std::string, std::string> parseCommandLine(const char** argv, int argc);

    };
    
}

#endif /* defined(__ParserExample__FUParser__) */
