Argument Parser
===============

Create a command line parser from a JSON definition.


This utility class parses command-line program arguments and imitates the gnu-argp behavior. Instead of a C-Struct a JSON-Structure is used to describe the parser.

Example:

<pre><code>#import "YAParser.h"

...

int main(int argc, const char* argv[]) 
{

@autoreleasepool {
   YAParser* parser = [[YAParser alloc] init];
   parser.versionTag = @"Version 0.42";
   parser.authorTag = @"Report bugs to &#60;GrouchoM@example.com&#62;

  [parser createParseTreeFromFile:@"parser.json"];

  NSDictionary* options = [parser parseCommandLime: argv Count: argc ];

  NSLog(@"My Options: %@", options);

}}
</code></pre> 

A parser definition looks like this:
<pre><code>
{
  "Doc":"myApp -- Something wonderful will happen.",
	"Argument":{"Argument":"INPUT", "Doc":"A short Description"},

	"Options":[
		{"Name":"outfile", "Key":"o", "Argument":"OUTFILE", "Doc":"Resulting output"}, 
		{"Name":"withoutargument", "Key":"w", "Doc":"Option without argument."}
	]
}
</code></pre>
