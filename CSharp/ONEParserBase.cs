
using System.IO;
using Antlr4.Runtime;


public abstract class ONEParserBase : Parser
{
    protected ONEParserBase(ITokenStream input)
        : base(input)
    {
    }

    protected ONEParserBase(ITokenStream input, TextWriter output, TextWriter errorOutput)
        : base(input, output, errorOutput)
    {
    }

    protected bool IsGlobalStatement()
    {
        if (this.Context is ONEParser.Member_declarationContext && this.Context.Parent is ONEParser.Compilation_unitContext)
        {
            //System.out.print(" [isGlobalStatement: " + isGlobalStatement + "] ");
            //System.out.println();
            return true;
        }
        else if (this.Context is ONEParser.Compilation_unitContext)
        {
            //System.out.print(" [isGlobalStatement: " + isGlobalStatement + "] ");
            //System.out.println();
            return true;
        }

        return false;
    }

    public override void Reset()
    {
        base.Reset(); // Is there anything else that should be done here ?
    }

    protected bool IsDeclaration()
    {
        bool isDeclaration = true;

        if (this.Context is ONEParser.Basic_statementContext || this.Context is ONEParser.ExpressionContext)
        {
            BufferedTokenStream stream = (BufferedTokenStream)TokenStream;
            int precedingTokenNumber = 0;

            for (int i = 1; i <= stream.Size; i++)
            {
                var token = ((CommonTokenStream)this.InputStream).LT(i);
                if (token.Type == ONELexer.NEWLINE || token.Type == ONELexer.ASSIGNMENT || token.Type == ONELexer.LT)
                    break;

                //System.out.print(token.getText());
                if (token.Type == ONELexer.OPEN_PARENS)
                {
                    //System.out.print(" [precedingTokenNumber: " + precedingTokenNumber + "] ");
                    var hiddenChannel = stream.GetHiddenTokensToLeft(token.TokenIndex, Lexer.Hidden);
                    if (hiddenChannel == null && precedingTokenNumber > 0)
                    {
                        isDeclaration = false;
                        break;
                    }
                }

                precedingTokenNumber++;
            }

            //System.out.print(" [isDeclaration: " + isDeclaration + "] ");
            //System.out.println();
        }

        return isDeclaration;
    }

    protected bool IsCaseTypeLabel()
    {
        bool isCaseTypeLabel = true;

        if (this.Context is ONEParser.One_switch_labelContext)
        {
            var token = ((CommonTokenStream)this.InputStream).LT(2);
            //System.out.print(token.getText());

            if (token.Type == ONELexer.OPEN_PARENS)
                isCaseTypeLabel = false;

            //System.out.print(" [isCaseTypeLabel: " + isCaseTypeLabel + "] ");
            //System.out.println();
        }

        return isCaseTypeLabel;
    }

    protected bool IsImplicitElementAccess()
    {
        bool isImplicitElementAccess = false;

        if (this.Context is ONEParser.Element_access_or_bindingContext)
        {
            for (int i = 1; i <= TokenStream.Size; i++)
            {
                var token = ((CommonTokenStream)this.InputStream).LT(i);
                if (token.Type == ONELexer.NEWLINE)
                    break;

                //System.out.print(token.getText());
                if (token.Type == ONELexer.ASSIGNMENT)
                {
                    isImplicitElementAccess = true;
                    break;
                }
            }

            //System.out.print(" [isImplicitElementAccess: " + isImplicitElementAccess + "] ");
            //System.out.println();
        }

        return isImplicitElementAccess;
    }

    protected bool IsCollectionExpression()
    {
        bool isCollectionExpression = false;

        if (this.Context is ONEParser.ExpressionContext)
        {
            isCollectionExpression = ((CommonTokenStream)this.InputStream).LT(-1).Type == ONELexer.ASSIGNMENT || ((CommonTokenStream)this.InputStream).LT(-1).Type == ONELexer.RETURN;
            if (!isCollectionExpression)
            {
                ONEParser.Collection_elementContext collectionParent = (ONEParser.Collection_elementContext)GetCollectionParentNode(this.Context);
                isCollectionExpression = collectionParent != null;
            }

            //System.out.print(" [isCollectionExpression: " + isCollectionExpression + "] ");
            //System.out.println();
        }

        return isCollectionExpression;
    }

    protected bool IsElementAccessOrBinding()
    {
        bool isElementAccessOrBinding = true;

        if (this.Context is ONEParser.ExpressionContext)
        {
            isElementAccessOrBinding = ((CommonTokenStream)this.InputStream).LT(-1).Type != ONELexer.IS;
            //System.out.print(" [isElementAccessOrBinding: " + isElementAccessOrBinding + "] ");
            //System.out.println();
        }

        return isElementAccessOrBinding;
    }

    protected bool IsDeclarationExpression()
    {
        bool isDeclarationExpression = true;

        if (this.Context is ONEParser.ExpressionContext)
        {
            ONEParser.Query_clauseContext queryParent = (ONEParser.Query_clauseContext)GetQueryParentNode(this.Context);
            isDeclarationExpression = queryParent == null && IsDeclaration() && ((CommonTokenStream)this.InputStream).LT(-1).Type != ONELexer.IS;

            //System.out.print(" [isDeclarationExpression: " + isDeclarationExpression + "] ");
            //System.out.println();
        }

        return isDeclarationExpression;
    }

    private static ParserRuleContext GetQueryParentNode(ParserRuleContext context)
    {
        ParserRuleContext parent = (ParserRuleContext)context.Parent;
        if (parent != null && !(parent is ONEParser.Query_clauseContext))
            parent = GetQueryParentNode((ParserRuleContext)parent);

        return parent;
    }

    private static ParserRuleContext GetCollectionParentNode(ParserRuleContext context)
    {
        ParserRuleContext parent = (ParserRuleContext)context.Parent;
        if (parent != null && !(parent is ONEParser.Collection_elementContext))
            parent = GetCollectionParentNode((ParserRuleContext)parent);

        return parent;
    }
}
