using System.IO;
using Antlr4.Runtime;

public abstract class ONE2ParserBase : Parser
{
    protected ONE2ParserBase(ITokenStream input)
        : base(input)
    {
    }

    protected ONE2ParserBase(ITokenStream input, TextWriter output, TextWriter errorOutput)
        : base(input, output, errorOutput)
    {
    }

    public override void Reset()
    {
        base.Reset();
    }

    protected bool IsLocalVariableDeclaration()
    {
        if (Context is ONE2Parser.Local_variable_declarationContext local_var_decl)
        {
            var local_variable_type = local_var_decl.local_variable_type();

            if (local_variable_type == null)
                return true;

            if (local_variable_type.GetText() == "var")
                return false;
        }

        return true;
    }
}
