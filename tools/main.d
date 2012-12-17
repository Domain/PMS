module main;

import std.stdio;
import std.getopt;
import std.file;
import std.exception;
import std.array;

string getFilename(string fullname)
{
	auto index = fullname.length;
	while (fullname[index-1] != '\\')
	{
		--index;
	}
	return fullname[index..$-2];
}

void generateFile(string dir, string prefix)
{
	enforce(dir.isDir());
	chdir(dir);
	auto path = dir.replace(prefix, "");
	path = path.replace("\\", ".");
	path = path[1..$];
	auto files = appender!string();
	foreach (string name; dirEntries(dir, SpanMode.shallow)) 
	{ 
		if (name.isFile() && name[$-2..$] == ".d")
		{
			auto filename = getFilename(name);

			if (filename != "all")
				files.put("public import " ~ path ~ "." ~ filename ~";\n");
		}
	}
	if (files.data != "")
	{
		auto f = File("all.d", "w");
		f.writeln("module " ~ path ~ ".all;\n");
		f.write(files.data);
		f.close();
	}
}

int main(string[] argv)
{
	if (argv.length != 2 && argv.length != 3)
	{
		writefln("Usage: %s <dir> [-r]", argv[0]);
		return 1;
	}

	auto dir = argv[1];
	auto r = false;
	if (argv.length == 3 && argv[2] == "-r")
	{
		r = true;
	}

	foreach (string name; dirEntries(dir, SpanMode.depth)) 
	{ 
		if (name.isDir())
		{
			generateFile(name, dir);
		}
	}
	return 0;
}
