import org.antlr.v4.runtime.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Collections;
import java.lang.reflect.Field;

public abstract class ONEParserBase extends Parser
{
    protected ONEParserBase(TokenStream input)
    {
	    super(input);
    }

    protected boolean IsGlobalStatement()
    {
        if (this._ctx instanceof ONEParser.Member_declarationContext && this._ctx.getParent() instanceof ONEParser.Compilation_unitContext)
        {       
            //System.out.print(" [isGlobalStatement: " + isGlobalStatement + "] ");
            //System.out.println();
            return true;
        }
        else if (this._ctx instanceof ONEParser.Compilation_unitContext)
        {
            //System.out.print(" [isGlobalStatement: " + isGlobalStatement + "] ");
            //System.out.println();
            return true;
        }

        return false;
    }

    @Override
    public void reset()
    {
        super.reset(); // Is there anything else that should be done here ?
    }

    protected boolean IsDeclaration()
    {
        boolean isDeclaration = true;

        if (this._ctx instanceof ONEParser.Basic_statementContext || this._ctx instanceof ONEParser.ExpressionContext)
        {
            BufferedTokenStream stream = (BufferedTokenStream)getTokenStream();
            int precedingTokenNumber = 0;
            
            for (int i = 1; i <= stream.size(); i++)
            {
                Token token = this._input.LT(i); 
                if (token.getType() == ONELexer.NEWLINE || token.getType() == ONELexer.ASSIGNMENT || token.getType() == ONELexer.LT)
                    break;
                
                //System.out.print(token.getText());
                if (token.getType() == ONELexer.OPEN_PARENS)
                {
                    //System.out.print(" [precedingTokenNumber: " + precedingTokenNumber + "] ");
                    List<Token> hiddenChannel = stream.getHiddenTokensToLeft(token.getTokenIndex(), Lexer.HIDDEN);
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

    protected boolean IsCaseTypeLabel()
    {
        boolean isCaseTypeLabel = true;

        if (this._ctx instanceof ONEParser.One_switch_labelContext)
        {
            Token token = this._input.LT(2); 
            //System.out.print(token.getText());

            if (token.getType() == ONELexer.OPEN_PARENS)
                isCaseTypeLabel = false;

            //System.out.print(" [isCaseTypeLabel: " + isCaseTypeLabel + "] ");
            //System.out.println();
        }

        return isCaseTypeLabel;
    }

    protected boolean IsImplicitElementAccess()
    {
        boolean isImplicitElementAccess = false;
        
        if (this._ctx instanceof ONEParser.Element_access_or_bindingContext)
        {
            for (int i = 1; i <= getTokenStream().size(); i++)
            {
                Token token = this._input.LT(i);
                if (token.getType() == ONELexer.NEWLINE)
                    break;

                //System.out.print(token.getText());
                if (token.getType() == ONELexer.ASSIGNMENT)
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

    protected boolean IsCollectionExpression()
    {
        boolean isCollectionExpression = false;
 
        if (this._ctx instanceof ONEParser.ExpressionContext)
        {
            isCollectionExpression = this._input.LT(-1).getType() == ONELexer.ASSIGNMENT || this._input.LT(-1).getType() == ONELexer.RETURN;
            if (!isCollectionExpression)
            {
                ONEParser.Collection_elementContext collectionParent = (ONEParser.Collection_elementContext)GetCollectionParentNode(this._ctx);
                isCollectionExpression = collectionParent != null;
            }
            
            //System.out.print(" [isCollectionExpression: " + isCollectionExpression + "] ");
            //System.out.println();
        }

        return isCollectionExpression;
    }

    protected boolean IsElementAccessOrBinding()
    {
        boolean isElementAccessOrBinding = true;
        
        if (this._ctx instanceof ONEParser.ExpressionContext)
        {
            isElementAccessOrBinding = this._input.LT(-1).getType() != ONELexer.IS;
            //System.out.print(" [isElementAccessOrBinding: " + isElementAccessOrBinding + "] ");
            //System.out.println();
        }

        return isElementAccessOrBinding;
    }

    protected boolean IsDeclarationExpression()
    {
        boolean isDeclarationExpression = true;

        if (this._ctx instanceof ONEParser.ExpressionContext)
        {
            ONEParser.Query_clauseContext queryParent = (ONEParser.Query_clauseContext)GetQueryParentNode(this._ctx);
            isDeclarationExpression = queryParent == null && IsDeclaration() && this._input.LT(-1).getType() != ONELexer.IS;

            //System.out.print(" [isDeclarationExpression: " + isDeclarationExpression + "] ");
            //System.out.println();
        }

        return isDeclarationExpression;
    }

    private static ParserRuleContext GetQueryParentNode(ParserRuleContext context)
    {
        ParserRuleContext parent = (ParserRuleContext)context.getParent();
        if (parent != null && !(parent instanceof ONEParser.Query_clauseContext))
            parent = GetQueryParentNode((ParserRuleContext)parent);

        return parent;
    }

    private static ParserRuleContext GetCollectionParentNode(ParserRuleContext context)
    {
        ParserRuleContext parent = (ParserRuleContext)context.getParent();
        if (parent != null && !(parent instanceof ONEParser.Collection_elementContext))
            parent = GetCollectionParentNode((ParserRuleContext)parent);

        return parent;
    }
}
