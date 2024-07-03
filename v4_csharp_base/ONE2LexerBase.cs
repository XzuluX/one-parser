using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Antlr4.Runtime;
using System.Text.RegularExpressions;

public abstract partial class ONE2LexerBase : Lexer
{
    private readonly ICharStream _input;
    protected int interpolatedStringLevel = 0;
    protected Stack<bool> interpolatedVerbatims = new Stack<bool>();
    protected Stack<int> curlyLevels = new Stack<int>();
    protected bool verbatim = false;

    // A queue where extra tokens are pushed on (see the NEWLINE lexer rule).
    private readonly LinkedList<IToken> Tokens = new LinkedList<IToken>();
    // The stack that keeps track of the indentation level.
    private readonly Stack<int> Indents = new Stack<int>();
    // The amount of opened braces, brackets and parenthesis.
    private int Opened = 0;
    // The most recently produced token.
    private IToken LastToken = null;
    // The stack that keeps track of the indentation level of current block
    private readonly Stack<int> BlockIndents = new Stack<int>();
    // Flag if functionblock / statemachine token was recognized 
    private bool FunctionBlockWasEntered = false;
    private bool StateMachineWasEntered = false;
    // Indentation inside functionblock / statemachine
    private int FunctionBlockIndentation = -1;
    private int StateMachineIndentation = -1;
    // Flag if lexer parses inside functionblock / statemachine
    private bool InsideFunctionBlockFlag = false;
    private bool InsideStateMachineFlag = false;
    // The starting number of double quotes for raw string literal
    private int NumberOfRawStringStartQuotes = 0;
    // The number of dollar signs for raw string literal
    private int NumberOfRawStringDollarSigns = 0;
    // Flag to calculate brace count for raw string literal
    private bool CalculateRawBraceCount = true;
    // The number of total open braces for raw string
    private int NumberOfOpenRawStringBraces = 0;
    // Flag if interpolation has to be checked
    private bool CheckInterpolation = false;
    // Number of starting braces for raw interpolated string
    private int NumberOfStartingBraces = 0;

    public ONE2LexerBase(ICharStream input)
        : base(input)
    {
        _input = input;
    }
    public ONE2LexerBase(ICharStream input, TextWriter output, TextWriter errorOutput)
        : base(input, output, errorOutput)
    {
        _input = input;
    }

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
                Mode(ONE2Lexer.INTERPOLATION_FORMAT);
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
        verbatim = interpolatedVerbatims.Count > 0 && interpolatedVerbatims.Peek();
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
        while ((char)_input.LA(-i) == '"')
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
        FunctionBlockWasEntered = true;
    }

    protected bool InsideFunctionBlock()
    {
        return InsideFunctionBlockFlag;
    }

    private void UpdateInsideFunctionBlockFlag(string spaces)
    {
        int currentIndentation = GetIndentationCount(spaces);

        if (FunctionBlockWasEntered)
        {
            FunctionBlockIndentation = currentIndentation;
            FunctionBlockWasEntered = false;
        }

        if (FunctionBlockIndentation != -1 && currentIndentation >= FunctionBlockIndentation)
            InsideFunctionBlockFlag = true;
        else
        {
            InsideFunctionBlockFlag = false;
            FunctionBlockIndentation = -1;
        }
    }

    protected void OnStateMachine()
    {
        if (!InsideStateMachineFlag)
            StateMachineWasEntered = true;
    }

    protected bool InsideStateMachine()
    {
        return InsideStateMachineFlag;
    }

    private void UpdateInsideStateMachineFlag(string spaces)
    {
        int currentIndentation = GetIndentationCount(spaces);

        if (StateMachineWasEntered)
        {
            StateMachineIndentation = currentIndentation;
            StateMachineWasEntered = false;
        }

        if (StateMachineIndentation != -1 && currentIndentation >= StateMachineIndentation)
            InsideStateMachineFlag = true;
        else
        {
            InsideStateMachineFlag = false;
            StateMachineIndentation = -1;
        }
    }

    /*** INDENT, DEDENT logic ***/
    public override void Emit(IToken token)
    {
        base.Token = token;
        Tokens.AddLast(token);
    }

    private CommonToken CommonToken(int type, string text)
    {
        int stop = CharIndex - 1;
        int start = text.Length == 0 ? stop : stop - text.Length + 1;
        return new CommonToken(Tuple.Create((ITokenSource)this, (ICharStream)InputStream), type, DefaultTokenChannel, start, stop);
    }

    private CommonToken CreateDedent()
    {
        var dedent = CommonToken(ONE2Parser.DEDENT, "");
        dedent.Line = LastToken.Line;
        return dedent;
    }

    public override void Reset()
    {
        base.Reset();
        ResetFields();
    }

    private void ResetFields()
    {
        interpolatedStringLevel = 0;
        interpolatedVerbatims.Clear();
        curlyLevels.Clear();
        verbatim = false;

        Tokens.Clear();
        Indents.Clear();
        Opened = 0;
        LastToken = null;
        BlockIndents.Clear();
        FunctionBlockWasEntered = false;
        StateMachineWasEntered = false;
        FunctionBlockIndentation = -1;
        StateMachineIndentation = -1;
        InsideFunctionBlockFlag = false;
        InsideStateMachineFlag = false;
        NumberOfRawStringStartQuotes = 0;
        NumberOfRawStringDollarSigns = 0;
        CalculateRawBraceCount = true;
        NumberOfOpenRawStringBraces = 0;
        CheckInterpolation = false;
        NumberOfStartingBraces = 0;
    }

    public override IToken NextToken()
    {
        // Check if the end-of-file is ahead and there are still some DEDENTS expected.
        if (((ICharStream)InputStream).LA(1) == Eof && Indents.Count != 0)
        {
            // Remove any trailing EOF tokens from our buffer.
            for (var node = Tokens.First; node != null;)
            {
                var temp = node.Next;
                if (node.Value.Type == Eof)
                {
                    Tokens.Remove(node);
                }
                node = temp;
            }

            // First emit an extra line break that serves as the end of the statement.
            Emit(CommonToken(ONE2Parser.NEWLINE, "\n"));

            // Now emit as much DEDENT tokens as needed.
            while (Indents.Count != 0)
            {
                Emit(CreateDedent());
                Indents.Pop();
            }

            // Put the EOF back on the token stream.
            Emit(CommonToken(ONE2Parser.Eof, "<EOF>"));
        }

        var next = base.NextToken();
        if (next.Channel == DefaultTokenChannel)
        {
            // Keep track of the last token on the default channel.
            LastToken = next;
        }

        if (Tokens.Count == 0)
        {
            return next;
        }
        else
        {
            var x = Tokens.First.Value;
            Tokens.RemoveFirst();
            return x;
        }
    }

    // Calculates the indentation of the provided spaces, taking the
    // following rules into account:
    //
    // "Tabs are replaced (from left to right) by one to eight spaces
    //  such that the total number of characters up to and including
    //  the replacement is a multiple of eight [...]"
    //
    //  -- https://docs.python.org/3.1/reference/lexical_analysis.html#indentation
    static int GetIndentationCount(string spaces)
    {
        int count = 0;
        foreach (char ch in spaces.ToCharArray())
        {
            count += ch == '\t' ? 8 - (count % 8) : 1;
        }
        return count;
    }

    public bool AtStartOfInput()
    {
        return Column == 0 && Line == 1;
    }

    public void OnOpenBrace()
    {
        Opened++;
    }

    public void OnCloseBrace()
    {
        Opened--;
    }

    public void OnNewLine()
    {
        var newLine = RegexReplaceNewLine().Replace(Text, "");
        var spaces = RegexReplaceSpaces().Replace(Text, "");

        // Strip newlines inside open clauses except if we are near EOF. We keep NEWLINEs near EOF to
        // satisfy the final newline needed by the single_put rule used by the REPL.
        int next = ((ICharStream)InputStream).LA(1);
        int nextnext = ((ICharStream)InputStream).LA(2);
        int nextnextnext = ((ICharStream)InputStream).LA(3);

        if (Opened > 0 || (nextnext != -1 && (next == '\r' || next == '\n' || next == '\f' || next == '#'
            || (next == '/' && nextnext == '/') || (next == '-' && nextnext == '-' && nextnextnext == '-'))))
        {
            // If we're inside a list or on a blank line, ignore all indents, 
            // dedents and line breaks.
            Skip();
        }
        else
        {
            UpdateInsideFunctionBlockFlag(spaces);
            UpdateInsideStateMachineFlag(spaces);

            int indent = GetIndentationCount(spaces);
            if (LastToken != null && (LastToken.Type == ONE2Parser.COLON || (next == '.' && nextnext == '.' && nextnextnext != '.'))) // cascading operator
                BlockIndents.Push(indent);
            else
            {
                int currentBlockIndent = BlockIndents.Count == 0 ? 0 : BlockIndents.Peek();
                if (indent > currentBlockIndent)
                {
                    Skip();
                    return;
                }
                else if (indent < currentBlockIndent)
                {
                    var blockIndentsList = BlockIndents.ToList();
                    blockIndentsList.RemoveAt(0);
                    blockIndentsList.Add(0);
                    bool indentMatch = false;

                    foreach (var blockIndent in blockIndentsList)
                    {
                        if (indent == blockIndent)
                        {
                            indentMatch = true;
                            break;
                        }
                    }

                    if (!indentMatch)
                        NotifyListeners(new LexerNoViableAltException(this, (ICharStream)InputStream, TokenStartLine + 1, null));
                }
            }

            Emit(CommonToken(ONE2Parser.NEWLINE, newLine));
            int previous = Indents.Count == 0 ? 0 : Indents.Peek();
            if (indent == previous)
            {
                // skip indents of the same size as the present indent-size
                Skip();
            }
            else if (indent > previous)
            {
                Indents.Push(indent);
                Emit(CommonToken(ONE2Parser.INDENT, spaces));
            }
            else
            {
                // Possibly emit more than 1 DEDENT token.
                while (Indents.Count != 0 && Indents.Peek() > indent)
                {
                    this.Emit(CreateDedent());
                    Indents.Pop();
                }

                while (BlockIndents.Count != 0 && BlockIndents.Peek() > indent)
                    BlockIndents.Pop();
            }
        }
    }

    [GeneratedRegex("[^\r\n\f]+")]
    private static partial Regex RegexReplaceNewLine();
    [GeneratedRegex("[\r\n\f]+")]
    private static partial Regex RegexReplaceSpaces();
}
