//
//  FUParser.cpp
//  ParserExample
//
//  Created by Yousry Abdallah on 22.04.15.
//  Copyright (c) 2015 Yousry Abdallah. All rights reserved.
//

#include <sstream>
#include <iomanip>
#include <iostream>
#include <fstream>
#include <functional>
#include <string>
#include <algorithm>

#include <json/config.h>
#include <json/reader.h>
#include <json/writer.h>
#include <json/value.h>

#include "FUParser.h"


#define TOKEN_ARGUMENT "Argument"
#define TOKEN_OPTIONS  "Options"
#define TOKEN_KEY  "Key"
#define TOKEN_NAME  "Name"
#define TOKEN_DOC  "Doc"
#define TOKEN_UNDEFINED "UNDEFINED"

#define TAG_UNSET "UNSET"

#define OPTION_VERSION "version"
#define OPTION_VERSION_SHORT "V"
#define OPTION_USAGE "usage"
#define OPTION_USAGE_SHORT "u"
#define OPTION_HELP "help"
#define OPTION_HELP_SHORT "h"

#define MAX_OPT_PER_LINE 5

using namespace Json;
using namespace std;
using namespace util;

// SOURCE: http://stackoverflow.com/questions/236129/split-a-string-in-c
vector<string> split(const string& s, const string& delim, const bool keep_empty = true);

std::string FUParser::getVersionTag()
{
    return _versionTag;
}

void FUParser::setVersionTag(std::string versionTag)
{
    _versionTag = versionTag;
}

std::string FUParser::getAuthorTag()
{
    return _authorTag;
}

void FUParser::setAuthorTag(std::string authorTag)
{
    _authorTag = authorTag;
}

std::map<std::string, std::string> FUParser::getparseTree()
{
    return _parseTree;
}

FUParser::FUParser(): _versionTag(TAG_UNSET), _authorTag(TAG_UNSET)
{
}

FUParser::~FUParser()
{
}

void FUParser::createParseTreeFromFile(std::string jsonFile)
{
    
    std::ifstream fstr(jsonFile, std::ifstream::binary);
    fstr >> argumentDictionary;
    defaultOptions();
}

void FUParser::createParseTreeFromString(std::string jsonString)
{
    Reader jsonReader;
    jsonReader.parse(jsonString, argumentDictionary);
    defaultOptions();
}

std::string FUParser::helpShortDescription()
{
    Json::Value argument = argumentDictionary[TOKEN_ARGUMENT];
    std::string argarg = argument[TOKEN_ARGUMENT].asString();


    std::ostringstream ostrstr;
    
   
    ostrstr << "Usage: " <<  appName << " [Option...] " << argarg << endl
             << "Try ` " << appName << " --help' or `" << appName << " --usage' for more information.";

    
    std::string usageString = ostrstr.str();
    
    return usageString;
}

std::string FUParser::usageDescription()
{

    int newLineCounter = 1;
    function<string (int)> senseNL = [&] (int tiles) {
        string result;
        newLineCounter++;
        if(!(newLineCounter % tiles))
            result.append("\n\t");
        return result;
    };
    
    string shortKeys;
    vector<string> optArgs;
    vector<string> optArgsShort;
    

    for(Value parseOption : parseOptions) {
        string optName = parseOption[TOKEN_NAME].asString();
        string optArgument = parseOption[TOKEN_ARGUMENT].asString();
        string optKey = parseOption[TOKEN_KEY].asString();
        
        string optArgString;
        string optArgShortString;
        
        if(optArgument.empty()) {
            shortKeys.append(optKey);
            std::ostringstream ostrstr;
            ostrstr << "[--" << optName << "]";
            optArgShortString.append(ostrstr.str());
        } else {
            std::ostringstream ostrstr;
            ostrstr << "[--"<< optName << "=" << optArgument << "]";
            optArgString.append(ostrstr.str());
            
            ostrstr.clear();
            ostrstr << "[-"<< optKey << " " << optArgument <<"]";
            optArgShortString.append(ostrstr.str());
            optArgsShort.push_back(optArgShortString);
        }
        
        optArgs.push_back(optArgString);
    }
    
    std::ostringstream ostrstr;
    ostrstr << "Usage: " << appName << " [-" << shortKeys << "uhv]";
    string result(ostrstr.str());

    for(auto optArgShort : optArgsShort) {
        std::ostringstream ostrstr;
        ostrstr << " " << optArgShort << senseNL(MAX_OPT_PER_LINE);
        result.append(ostrstr.str());
    }

    for(auto optArg : optArgs) {
        std::ostringstream ostrstr;
        ostrstr << " " << optArg << senseNL(MAX_OPT_PER_LINE);
        result.append(ostrstr.str());
    }
    
    Value argument = argumentDictionary[TOKEN_ARGUMENT];
    string argarg = argument[TOKEN_ARGUMENT].asString();

    if(!argarg.empty()) {
        result.append(" ");
        result.append(argarg);
    }
    
    
    return result;
}

std::string FUParser::helpDescription()
{
    
    string result = usageDescription();
    
    result.append("\n");
    result.append(argumentDictionary[TOKEN_DOC].asString());
    result.append("\n"); // CBB!

    for(Value parseOption : parseOptions) {
        string optName = parseOption[TOKEN_NAME].asString();
        string optArgument = parseOption[TOKEN_ARGUMENT].asString();
        string optKey = parseOption[TOKEN_KEY].asString();
        string optDoc = parseOption[TOKEN_DOC].asString();

        string lineResult = "\n -";
        lineResult.append(optKey);
        lineResult.append(", --");
        lineResult.append(optName);

        if(!optArgument.empty()) {
            lineResult.append("=");
            lineResult.append(optArgument);
        }
       
        std::ostringstream ostrstr;
        ostrstr << std::setw(30) << lineResult;
        
        lineResult.clear();
        lineResult.append(ostrstr.str());

        result.append(lineResult);
        result.append(optDoc);
    }
    
    
    result.append("\n  -h, --help                 Give this help list");
    result.append("\n  -u  --usage                Give a short usage message");
    result.append("\n  -V, --version              Print program version");
    result.append("\n\nMandatory or optional arguments to long options are also mandatory or optional\nfor any corresponding short options.\n\n");
    result.append(_authorTag);
    return result;
}


std::map<std::string, std::string> FUParser::parseCommandLine(const char** argv, int argc)
{
    appName.append(argv[0]);
    
    function<bool (string, string)> hasPrefix = [] (string bs, string ps) {
        auto result = std::mismatch(ps.begin(), ps.end(), bs.begin());
        return (result.first == ps.end());
    };
    
    function<bool (string, bool)> requestHelp = [&] (string opt, bool isShort) {
        
        if(    (  opt == OPTION_VERSION        && !isShort )
           || (  opt == OPTION_VERSION_SHORT  && isShort  ) ) {
            string vt = getVersionTag();
            cout << vt << endl;
            return true;
        } else if(   ( opt == OPTION_USAGE       && !isShort )
                  || ( opt == OPTION_USAGE_SHORT && isShort  ) ) {
            string ut = usageDescription();
            cout << ut << endl;
            return true;
        } else if(  ( opt == OPTION_HELP      && !isShort )
                  || ( opt == OPTION_HELP_SHORT && isShort ) ) {
            string hd = helpDescription();
            cout << hd << endl;
            return true;
        } else
            return false;
    };
    
    std::map<std::string, std::string> result;

    
    for(int i = 1; i < argc; i++) {
        
        string opt(argv[i]);
        string shortOpt;
        string longOpt;
        string arg;

        string prefix = "--";
        if(opt.substr(0, prefix.size()) == prefix && opt.size() > 2) {
            
            vector<string> optAndVal = split(opt,"=", false);
            
            if(optAndVal.size() == 2) {
                longOpt = optAndVal[0];
                longOpt = longOpt.substr(2);
                arg = optAndVal[1];
            } else {
                longOpt = opt.substr(2);
            }
            
        } else if( hasPrefix(opt, "-") && opt.size() > 1 &&  opt.at(1) != '-' ) {
            shortOpt = opt.substr(1);
        } else {
            Value argument = argumentDictionary[TOKEN_ARGUMENT];
            if(!argument.empty()) {
                string argarg = argument[TOKEN_ARGUMENT].asString();
                if(!argarg.empty())
                    result[argarg] = opt;
            }
        }
        
        if(!shortOpt.empty() || !longOpt.empty()) {
            const bool isShortOpt = !shortOpt.empty();
            
            const bool needHelp = isShortOpt ? requestHelp(shortOpt, true) : requestHelp(longOpt, false);
            if(needHelp) {
                result.clear();
                return result;
            }
            
            for(Value parseOption : parseOptions) {
                string tokenName = parseOption[TOKEN_NAME].asString();
                if(( isShortOpt && parseOption[TOKEN_KEY].asString() == shortOpt ) ||
                   ( !isShortOpt &&  tokenName == longOpt ) ) {
                    
                    bool hasArgument = !parseOption[TOKEN_ARGUMENT].empty();
                    
                    if(hasArgument && arg.empty()) {
                        string argvS(argv[i+1]);
                        if(i + 1 >= argc || hasPrefix(argvS, "-")) {
                            cerr << appName << ": option requires an argument -- " << opt << endl;
                            cerr << helpShortDescription();
                            result.clear();
                            return result;
                        } else {
                            arg =string(argv[++i]);
                            
                        }
                    }
                    
                    if(arg.empty() || !hasArgument)
                        arg = TOKEN_UNDEFINED;
                    
                    result[tokenName] = arg;
                }
            }
        }
    }
    
    return result;
}

void FUParser::defaultOptions()
{
    parseOptions = argumentDictionary[TOKEN_OPTIONS];
}


#pragma mark --
#pragma mark internal

vector<string> split(const string& s, const string& delim, const bool keep_empty) {
    vector<string> result;
    if (delim.empty()) {
        result.push_back(s);
        return result;
    }
    string::const_iterator substart = s.begin(), subend;
    while (true) {
        subend = search(substart, s.end(), delim.begin(), delim.end());
        string temp(substart, subend);
        if (keep_empty || !temp.empty()) {
            result.push_back(temp);
        }
        if (subend == s.end()) {
            break;
        }
        substart = subend + delim.size();
    }
    return result;
}

