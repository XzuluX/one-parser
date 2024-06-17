
import org.antlr.v4.runtime.*;
import java.util.Stack;
import java.util.ArrayList;
import java.util.List;

abstract class ONELexerBase extends Lexer {
    protected ONELexerBase(CharStream input) {
        super(input);
    }

    protected int interpolatedStringLevel;
    protected Stack<Boolean> interpolatedVerbatims = new Stack<Boolean>();
    protected Stack<Integer> curlyLevels = new Stack<Integer>();
    protected boolean verbatim;

    // A queue where extra tokens are pushed on (see the NEWLINE lexer rule).
    private java.util.LinkedList<Token> tokens = new java.util.LinkedList<>();
    // The stack that keeps track of the indentation level.
    private java.util.Stack<Integer> indents = new java.util.Stack<>();
    // The amount of opened braces, brackets and parenthesis.
    private int opened = 0;
    // The most recently produced token.
    private Token lastToken = null;
    // The stack that keeps track of the indentation level of current block
    private java.util.Stack<Integer> BlockIndents = new java.util.Stack<>();
    // Flag if functionblock / statemachine token was recognized 
    private boolean functionBlockWasEntered = false;
    private boolean stateMachineWasEntered = false;
    // Indentation inside functionblock / statemachine
    private int functionBlockIndentation = -1;
    private int stateMachineIndentation = -1;
    // Flag if lexer parses inside functionblock / statemachine
    private boolean insideFunctionBlockFlag = false;
    private boolean insideStateMachineFlag = false;
     // The starting number of double quotes for raw string literal
    private int NumberOfRawStringStartQuotes = 0;
    // The number of dollar signs for raw string literal
    private int NumberOfRawStringDollarSigns = 0;
    // Flag to calculate brace count for raw string literal
    private boolean CalculateRawBraceCount = true;
    // The number of total braces for raw string
    private int NumberOfOpenRawStringBraces = 0;
    // Flag if interpolation has to be checked
    private boolean CheckInterpolation = false;
    // Number of starting braces for raw interpolated string
    private int NumberOfStartingBraces = 0;

    protected void OnInterpolatedRegularStringStart()
    {
        interpolatedStringLevel++;
        interpolatedVerbatims.push(false);
        verbatim = false;
    }

    protected void OnInterpolatedVerbatimStringStart()
    {
        interpolatedStringLevel++;
        interpolatedVerbatims.push(true);
        verbatim = true;
    }

    protected void OnOpenBraceCheckInterpolated()
    {
        if (interpolatedStringLevel > 0)
        {
            curlyLevels.push(curlyLevels.pop() + 1);
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
            curlyLevels.push(curlyLevels.pop() - 1);
            if (curlyLevels.peek() == 0)
            {
                curlyLevels.pop();
                skip();
                popMode();
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
            boolean switchToFormatString = true;
            while ((char)_input.LA(ind) != '}')
            {
                if (_input.LA(ind) == ')')
                {
                    switchToFormatString = false;
                    break;
                }
                ind++;
            }
            if (switchToFormatString)
            {
                mode(ONELexer.INTERPOLATION_FORMAT);
            }
        }
    }

    protected void OpenBraceInside()
    {
        curlyLevels.push(1);
    }

    protected void OnDoubleQuoteInside()
    {
        interpolatedStringLevel--;
        interpolatedVerbatims.pop();
        verbatim = (interpolatedVerbatims.size() > 0 ? interpolatedVerbatims.peek() : false);
    }

    protected void OnCloseBraceInside()
    {
        curlyLevels.pop();
    }

    protected boolean IsRegularCharInside()
    {
        return !verbatim;
    }

    protected boolean IsVerbatimDoubleQuoteInside()
    {
        return verbatim;
    }

    protected void OnCountDollarStart()
    {
        int i = 1;
        while ((char)_input.LA(-i) == '$')
        {
            i++;
            NumberOfRawStringDollarSigns++;
        }

        interpolatedStringLevel++;
    }

    protected void OnCountQuotesStart()
    {
        int i = 1;
        while ((char)_input.LA(-i) == '"')
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
            while ((char)_input.LA(i) == '{')
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
                skip();
                pushMode(DEFAULT_MODE);

                CalculateRawBraceCount = true;
                CheckInterpolation = false;
                NumberOfOpenRawStringBraces = 0;
                NumberOfStartingBraces = 0;
                curlyLevels.push(1);
            }
        }
    }

    protected boolean IsRawStringLiteralEnd()
    {
        boolean isRawStringLiteralEnd = false;
        int i = 1;
        while ((char)_input.LA(-i) == '"')
        {
            if (i == NumberOfRawStringStartQuotes)
            {
                if (NumberOfRawStringDollarSigns > 0)
                    interpolatedStringLevel--;
                
                NumberOfRawStringDollarSigns = 0;
                NumberOfRawStringStartQuotes = 0;
                isRawStringLiteralEnd = true;
                popMode();
            }
            i++;
        }

        return isRawStringLiteralEnd;
    }

    protected void OnFunctionBlock()
    {
        functionBlockWasEntered = true;
    }

    protected boolean InsideFunctionBlock()
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

    protected boolean InsideStateMachine()
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

    protected boolean IsOperator()
    {
        List<Character> characters = new ArrayList<Character>();
        int i = 1;
        
        do
        {
            char currentChar = (char)_input.LA(i);
            if (currentChar != ' ')
                characters.add(currentChar);
            i++;

        } while ((char)_input.LA(i - 1) != '\r' && (char)_input.LA(i) != '\n' && characters.size() < 2 );

        char firstChar = characters.get(0);
        boolean isOperator;
        
        if (firstChar == '(')
            isOperator = characters.size() <= 1 || characters.get(1) != ')';
        else
            isOperator = !(firstChar == '\r' || firstChar == '=' || firstChar == '[' 
                || firstChar == '{' || firstChar == ',' || firstChar == ')');

        return isOperator;
    }

    @Override
    public void emit(Token t) {
        super.setToken(t);
        tokens.offer(t);
    }

    @Override
    public Token nextToken() {
        // Check if the end-of-file is ahead and there are still some DEDENTS expected.
        if (_input.LA(1) == EOF && !this.indents.isEmpty()) {
            // Remove any trailing EOF tokens from our buffer.
            for (int i = tokens.size() - 1; i >= 0; i--) {
                if (tokens.get(i).getType() == EOF) {
                    tokens.remove(i);
                }
            }

            // First emit an extra line break that serves as the end of the statement.
            this.emit(commonToken(ONELexer.NEWLINE, "\n"));

            // Now emit as much DEDENT tokens as needed.
            while (!indents.isEmpty()) {
                this.emit(createDedent());
                indents.pop();
            }

            // Put the EOF back on the token stream.
            this.emit(commonToken(ONELexer.EOF, "<EOF>"));
        }

        Token next = super.nextToken();

        if (next.getChannel() == Token.DEFAULT_CHANNEL) {
            // Keep track of the last token on the default channel.
            this.lastToken = next;
        }

        return tokens.isEmpty() ? next : tokens.poll();
    }

    private Token createDedent() {
        CommonToken dedent = commonToken(ONELexer.DEDENT, "");
        dedent.setLine(this.lastToken.getLine());
        return dedent;
    }

    @Override
    public void reset()
    {
        super.reset();
        resetFields();
    }

    private void resetFields()
    {
        interpolatedStringLevel = 0;
        interpolatedVerbatims.clear();
        curlyLevels.clear();
        verbatim = false;

        tokens.clear();
        indents.clear();
        opened = 0;
        lastToken = null;
        BlockIndents.clear();
        functionBlockWasEntered = false;
        stateMachineWasEntered = false;
        functionBlockIndentation = -1;
        stateMachineIndentation = -1;
        insideFunctionBlockFlag = false;
        insideStateMachineFlag = false;
        NumberOfRawStringStartQuotes = 0;
        NumberOfRawStringDollarSigns = 0;
        CalculateRawBraceCount = true;
        NumberOfOpenRawStringBraces = 0;
        CheckInterpolation = false;
        NumberOfStartingBraces = 0;
    }

    private CommonToken commonToken(int type, String text) {
        int stop = this.getCharIndex() - 1;
        int start = text.isEmpty() ? stop : stop - text.length() + 1;
        return new CommonToken(this._tokenFactorySourcePair, type, DEFAULT_TOKEN_CHANNEL, start, stop);
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
        for (char ch : spaces.toCharArray()) {
            switch (ch) {
                case '\t':
                    count += 8 - (count % 8);
                    break;
                default:
                    // A normal space char.
                    count++;
            }
        }

        return count;
    }

    boolean AtStartOfInput() {
        return super.getCharPositionInLine() == 0 && super.getLine() == 1;
    }

    void OnOpenBrace(){
        this.opened++;
    }

    void OnCloseBrace(){
        this.opened--;
    }

    void OnNewLine(){
        String newLine = getText().replaceAll("[^\r\n\f]+", "");
        String spaces = getText().replaceAll("[\r\n\f]+", "");

        // Strip newlines inside open clauses except if we are near EOF. We keep NEWLINEs near EOF to
        // satisfy the final newline needed by the single_put rule used by the REPL.
        int next = _input.LA(1);
        int nextnext = _input.LA(2);
        int nextnextnext = _input.LA(3);

        if (opened > 0 || (nextnext != -1 && (next == '\r' || next == '\n' || next == '\f' || next == '#' 
            || (next == '/' && nextnext == '/') || (next == '-' && nextnext == '-' && nextnextnext == '-')))) {
            // If we're inside a list or on a blank line, ignore all indents,
            // dedents and line breaks.
            skip();
        }
        else {
            UpdateInsideFunctionBlockFlag(spaces);
            UpdateInsideStateMachineFlag(spaces);

            
            int indent = getIndentationCount(spaces);
            if (lastToken != null && (lastToken.getType() == ONEParser.COLON || (next == '.' && nextnext == '.' && nextnextnext != '.'))) // cascading operator
                BlockIndents.push(indent);
            else
            {
                int currentBlockIndent = BlockIndents.isEmpty() ? 0 : BlockIndents.peek();
                if (indent > currentBlockIndent)
                {
                    skip();
                    return;
                }
                else if(indent < currentBlockIndent)
                {
                    java.util.LinkedList<Integer> blockIndentsList = new java.util.LinkedList<>();
                    Stack<Integer> copiedBlockIndents = new Stack<Integer>();
                    copiedBlockIndents.addAll(BlockIndents);
                    while(!copiedBlockIndents.isEmpty()) { 
                        blockIndentsList.add(copiedBlockIndents.pop());
                    }

                    blockIndentsList.remove(0);
                    blockIndentsList.add(0);
                    boolean indentMatch = false;

                    
                    for (Integer blockIndent : blockIndentsList)
                    { 
                        if (indent == blockIndent)
                        {
                            indentMatch = true;
                            break;
                        }
                    }

                    if (!indentMatch)
                        notifyListeners(new LexerNoViableAltException(this, _input, getLine() + 1, null));
                }
            }
            
            emit(commonToken(ONELexer.NEWLINE, newLine));
            int previous = indents.isEmpty() ? 0 : indents.peek();
            if (indent == previous) {
                // skip indents of the same size as the present indent-size
                skip();
            }
            else if (indent > previous) {
                indents.push(indent);
                emit(commonToken(ONELexer.INDENT, spaces));
            }
            else {
                // Possibly emit more than 1 DEDENT token.
                while(!indents.isEmpty() && indents.peek() > indent) {
                    this.emit(createDedent());
                    indents.pop();
                }

                while(!BlockIndents.isEmpty() && BlockIndents.peek() > indent) {
                    BlockIndents.pop();
                }
            }
        }
    }
}