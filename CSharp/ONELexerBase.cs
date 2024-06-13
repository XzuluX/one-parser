
using Antlr4.Runtime;
using System.Collections.Generic;
using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

public abstract class ONELexerBase : Lexer {

	public ONELexerBase(ICharStream input)
			: base(input)
	{
	}
	public ONELexerBase(ICharStream input, TextWriter output, TextWriter errorOutput)
			: base(input, output, errorOutput)
	{
	}


    protected int interpolatedStringLevel;
    protected Stack<bool> interpolatedVerbatims = new Stack<bool>();
    protected Stack<int> curlyLevels = new Stack<int>();
    protected bool verbatim;

    // A queue where extra tokens are pushed on (see the NEWLINE lexer rule).
    private List<IToken> tokens = new List<IToken>();
    // The stack that keeps track of the indentation level.
    private Stack<int> indents = new Stack<int>();
    // The amount of opened braces, brackets and parenthesis.
    private int opened = 0;
    // The most recently produced token.
    private IToken lastToken = null;
    // The stack that keeps track of the indentation level of current block
    private Stack<int> BlockIndents = new Stack<int>();
    // Flag if functionblock / statemachine token was recognized 
    private bool functionBlockWasEntered = false;
    private bool stateMachineWasEntered = false;
    // Indentation inside functionblock / statemachine
    private int functionBlockIndentation = -1;
    private int stateMachineIndentation = -1;
    // Flag if lexer parses inside functionblock / statemachine
    private bool insideFunctionBlockFlag = false;
    private bool insideStateMachineFlag = false;
     // The starting number of double quotes for raw string literal
    private int NumberOfRawStringStartQuotes = 0;
    // The number of dollar signs for raw string literal
    private int NumberOfRawStringDollarSigns = 0;
    // Flag to calculate brace count for raw string literal
    private bool CalculateRawBraceCount = true;
    // The number of total braces for raw string
    private int NumberOfOpenRawStringBraces = 0;
    // Flag if interpolation has to be checked
    private bool CheckInterpolation = false;
    // Number of starting braces for raw interpolated string
    private int NumberOfStartingBraces = 0;

    protected void OnInterpolatedRegularStringStart()
    {
        interpolatedStringLevel++;
        interpolatedVerbatims.Push(false);
        verbatim = false;
    }

    protected void OnInterpolatedVerbatimStringStart()
    {
        interpolatedStringLevel++;
        interpolatedVerbatims.Push(true);
        verbatim = true;
    }

    protected void OnOpenBraceCheckInterpolated()
    {
        if (interpolatedStringLevel > 0)
        {
            curlyLevels.Push(curlyLevels.Pop() + 1);
        }
        else
        {
            OnOpenBrace();
        }
    }

    protected void OnCloseBraceCheckInterpolated()
    {
        if (interpolatedStringLevel > 0)
        {
            curlyLevels.Push(curlyLevels.Pop() - 1);
            if (curlyLevels.Peek() == 0)
            {
                curlyLevels.Pop();
                Skip();
                PopMode();
            }
        }
        else
        {
            OnCloseBrace();
        }
    }

    protected void OnColon()
    {
        if (interpolatedStringLevel > 0)
        {
            int ind = 1;
            bool switchToFormatString = true;
            while ((char)InputStream.LA(ind) != '}')
            {
                if (InputStream.LA(ind) == ')')
                {
                    switchToFormatString = false;
                    break;
                }
                ind++;
            }
            if (switchToFormatString)
            {
                this.PushMode(ONELexer.INTERPOLATION_FORMAT);
            }
        }
    }

    protected void OpenBraceInside()
    {
        curlyLevels.Push(1);
    }

    protected void OnDoubleQuoteInside()
    {
        interpolatedStringLevel--;
        interpolatedVerbatims.Pop();
        verbatim = (interpolatedVerbatims.Count > 0 ? interpolatedVerbatims.Peek() : false);
    }

    protected void OnCloseBraceInside()
    {
        curlyLevels.Pop();
    }

    protected bool IsRegularCharInside()
    {
        return !verbatim;
    }

    protected bool IsVerbatimDoubleQuoteInside()
    {
        return verbatim;
    }

    protected void OnCountDollarStart()
    {
        int i = 1;
        while ((char)InputStream.LA(-i) == '$')
        {
            i++;
            NumberOfRawStringDollarSigns++;
        }

        interpolatedStringLevel++;
    }

    protected void OnCountQuotesStart()
    {
        int i = 1;
        while ((char)InputStream.LA(-i) == '"')
        {
            i++;
            NumberOfRawStringStartQuotes++;
        }
    }

    protected void OnRawStringOpenBrace()
    {
        if (CalculateRawBraceCount)
        {
            int i = 1;
            while ((char)InputStream.LA(i) == '{')
                i++;

            NumberOfOpenRawStringBraces = i;
            if (i >= NumberOfRawStringDollarSigns)
            {
                CalculateRawBraceCount = false;
                CheckInterpolation = true;
            }
        }

        CheckInterpolationState();
    }

    private void CheckInterpolationState()
    {
        if (CheckInterpolation)
        {
            NumberOfStartingBraces++;
            if (NumberOfStartingBraces >= NumberOfOpenRawStringBraces &&
                NumberOfOpenRawStringBraces >= NumberOfRawStringDollarSigns)
            {
                Skip();
                PushMode(DEFAULT_MODE);

                CalculateRawBraceCount = true;
                CheckInterpolation = false;
                NumberOfOpenRawStringBraces = 0;
                NumberOfStartingBraces = 0;
                curlyLevels.Push(1);
            }
        }
    }

    protected bool IsRawStringLiteralEnd()
    {
        bool isRawStringLiteralEnd = false;
        int i = 1;
        while ((char)InputStream.LA(-i) == '"')
        {
            if (i == NumberOfRawStringStartQuotes)
            {
                if (NumberOfRawStringDollarSigns > 0)
                    interpolatedStringLevel--;
                
                NumberOfRawStringDollarSigns = 0;
                NumberOfRawStringStartQuotes = 0;
                isRawStringLiteralEnd = true;
                PopMode();
            }
            i++;
        }

        return isRawStringLiteralEnd;
    }

    protected void OnFunctionBlock()
    {
        functionBlockWasEntered = true;
    }

    protected bool InsideFunctionBlock()
    {
        return insideFunctionBlockFlag;
    }

    private void UpdateInsideFunctionBlockFlag(String spaces)
    {
        int currentIndentation = getIndentationCount(spaces);

        if (functionBlockWasEntered)
        {
            functionBlockIndentation = currentIndentation;
            functionBlockWasEntered = false;
        }

        if (functionBlockIndentation != -1 && currentIndentation >= functionBlockIndentation)
            insideFunctionBlockFlag = true;
        else
        {
            insideFunctionBlockFlag = false;
            functionBlockIndentation = -1;
        }
    }

    protected void OnStateMachine()
    {
        if (!insideStateMachineFlag)
            stateMachineWasEntered = true;
    }

    protected bool InsideStateMachine()
    {
        return insideStateMachineFlag;
    }

    private void UpdateInsideStateMachineFlag(String spaces)
    {
        int currentIndentation = getIndentationCount(spaces);

        if (stateMachineWasEntered)
        {
            stateMachineIndentation = currentIndentation;
            stateMachineWasEntered = false;
        }

        if (stateMachineIndentation != -1 && currentIndentation >= stateMachineIndentation)
            insideStateMachineFlag = true;
        else
        {
            insideStateMachineFlag = false;
            stateMachineIndentation = -1;
        }
    }

    protected bool IsOperator()
    {
        List<char> characters = new List<char>();
        int i = 1;
        
        do
        {
            char currentChar = (char)InputStream.LA(i);
            if (currentChar != ' ')
                characters.Add(currentChar);
            i++;

        } while ((char)InputStream.LA(i - 1) != '\r' && (char)InputStream.LA(i) != '\n' && characters.Count < 2 );

        char firstChar = characters[0];
        bool isOperator;
        
        if (firstChar == '(')
            isOperator = characters.Count <= 1 || characters[1] != ')';
        else
            isOperator = !(firstChar == '\r' || firstChar == '=' || firstChar == '[' 
                || firstChar == '{' || firstChar == ',' || firstChar == ')');

        return isOperator;
    }

    public override void Emit(IToken t) {
        base.Token = t;
        tokens.Add(t);
    }

    public override IToken NextToken() {
        // Check if the end-of-file is ahead and there are still some DEDENTS expected.
        if (InputStream.LA(1) == Eof && this.indents.Count != 0) {
            // Remove any trailing EOF tokens from our buffer.
            for (int i = tokens.Count - 1; i >= 0; i--) {
                if (tokens[i].Type == Eof) {
                    tokens.RemoveAt(i);
                }
            }

            // First emit an extra line break that serves as the end of the statement.
            this.Emit(commonToken(ONELexer.NEWLINE, "\n"));

            // Now emit as much DEDENT tokens as needed.
            while (indents.Any()) {
                this.Emit(createDedent());
                indents.Pop();
            }

            // Put the EOF back on the token stream.
            this.Emit(commonToken(ONELexer.Eof, "<EOF>"));
        }

        var next = base.NextToken();

        if (next.Channel == DefaultTokenChannel) {
            // Keep track of the last token on the default channel.
            this.lastToken = next;
        }

        if (tokens.Count == 0)
        {
            return next;
        }
        else
        {
            var x = tokens[0];
            tokens.RemoveAt(0);
            return x;
        }
    }

    private IToken createDedent() {
        CommonToken dedent = commonToken(ONELexer.DEDENT, "");
        dedent.Line = this.lastToken.Line;
        return dedent;
    }

    private CommonToken commonToken(int type, String text) {
        int stop = this.CharIndex - 1;
        int start = text.Length == 0 ? stop : stop - text.Length + 1;
        return new CommonToken(Tuple.Create((ITokenSource)this, (ICharStream)InputStream), type, DefaultTokenChannel, start, stop);
    }

    // Calculates the indentation of the provided spaces, taking the
    // following rules into account:
    //
    // "Tabs are replaced (from left to right) by one to eight spaces
    //  such that the total number of characters up to and including
    //  the replacement is a multiple of eight [...]"
    //
    //  -- https://docs.python.org/3.1/reference/lexical_analysis.html#indentation
    static int getIndentationCount(String spaces) {
        int count = 0;
        foreach (char ch in spaces) {
            count += ch == '\t' ? 8 - (count % 8) : 1;
        }

        return count;
    }

    public bool AtStartOfInput() {
        return Column == 0 && Line == 1;
    }

    public void OnOpenBrace(){
        this.opened++;
    }

    public void OnCloseBrace(){
        this.opened--;
    }

    public void OnNewLine(){
        var newLine = (new Regex("[^\r\n\f]+")).Replace(Text, "");
        var spaces = (new Regex("[\r\n\f]+")).Replace(Text, "");

        // Strip newlines inside open clauses except if we are near EOF. We keep NEWLINEs near EOF to
        // satisfy the final newline needed by the single_put rule used by the REPL.
        int next = ((ICharStream)InputStream).LA(1);
        int nextnext = ((ICharStream)InputStream).LA(2);
        int nextnextnext = ((ICharStream)InputStream).LA(3);

        if (opened > 0 || (nextnext != -1 && (next == '\r' || next == '\n' || next == '\f' || next == '#' 
            || (next == '/' && nextnext == '/') || (next == '-' && nextnext == '-' && nextnextnext == '-')))) {
            // If we're inside a list or on a blank line, ignore all indents,
            // dedents and line breaks.
            Skip();
        }
        else {
            UpdateInsideFunctionBlockFlag(spaces);
            UpdateInsideStateMachineFlag(spaces);

            
            int indent = getIndentationCount(spaces);
            if (lastToken != null && (lastToken.Type == ONEParser.COLON || (next == '.' && nextnext == '.' && nextnextnext != '.'))) // cascading operator
                BlockIndents.Push(indent);
            else
            {
                int currentBlockIndent = BlockIndents.Count == 0 ? 0 : BlockIndents.Peek();
                if (indent > currentBlockIndent)
                {
                    Skip();
                    return;
                }
                else if(indent < currentBlockIndent)
                {
                    LinkedList<int> blockIndentsList = new LinkedList<int>();
                    Stack<int> copiedBlockIndents = new Stack<int>();
                    foreach (int BlockIndents in BlockIndents)
                        copiedBlockIndents.Push(BlockIndents);
                    while(copiedBlockIndents.Any()) { 
                        blockIndentsList.AddLast(copiedBlockIndents.Pop());
                    }

                    blockIndentsList.Remove(0);
                    blockIndentsList.AddLast(0);
                    bool indentMatch = false;

                    
                    foreach (int blockIndent in blockIndentsList)
                    { 
                        if (indent == blockIndent)
                        {
                            indentMatch = true;
                            break;
                        }
                    }

                    if (!indentMatch)
                        NotifyListeners(new LexerNoViableAltException(this, (ICharStream)InputStream, Line + 1, null));
                }
            }
            
            Emit(commonToken(ONELexer.NEWLINE, newLine));
            int previous = (!indents.Any()) ? 0 : indents.Peek();
            if (indent == previous) {
                // skip indents of the same size as the present indent-size
                Skip();
            }
            else if (indent > previous) {
                indents.Push(indent);
                Emit(commonToken(ONELexer.INDENT, spaces));
            }
            else {
                // Possibly emit more than 1 DEDENT token.
                while(indents.Any() && indents.Peek() > indent) {
                    this.Emit(createDedent());
                    indents.Pop();
                }

                while(BlockIndents.Any() && BlockIndents.Peek() > indent) {
                    BlockIndents.Pop();
                }
            }
        }
    }
}