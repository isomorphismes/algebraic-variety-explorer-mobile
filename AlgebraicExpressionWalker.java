// $ANTLR 3.4 /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g 2026-07-26 21:28:06

package de.mfo.jsurf.parser;

import de.mfo.jsurf.algebra.*;


import org.antlr.runtime.*;
import org.antlr.runtime.tree.*;
import java.util.Stack;
import java.util.List;
import java.util.ArrayList;

@SuppressWarnings({"all", "warnings", "unchecked"})
public class AlgebraicExpressionWalker extends TreeParser {
    public static final String[] tokenNames = new String[] {
        "<invalid>", "<EOR>", "<DOWN>", "<UP>", "DECIMAL_LITERAL", "DIGIT", "DIV", "ERRCHAR", "EXPONENT", "FLOATING_POINT_LITERAL", "IDENTIFIER", "LETTER", "LPAR", "MINUS", "MULT", "PARENTHESES", "PLUS", "POW", "RPAR", "WHITESPACE"
    };

    public static final int EOF=-1;
    public static final int DECIMAL_LITERAL=4;
    public static final int DIGIT=5;
    public static final int DIV=6;
    public static final int ERRCHAR=7;
    public static final int EXPONENT=8;
    public static final int FLOATING_POINT_LITERAL=9;
    public static final int IDENTIFIER=10;
    public static final int LETTER=11;
    public static final int LPAR=12;
    public static final int MINUS=13;
    public static final int MULT=14;
    public static final int PARENTHESES=15;
    public static final int PLUS=16;
    public static final int POW=17;
    public static final int RPAR=18;
    public static final int WHITESPACE=19;

    // delegates
    public TreeParser[] getDelegates() {
        return new TreeParser[] {};
    }

    // delegators


    public AlgebraicExpressionWalker(TreeNodeStream input) {
        this(input, new RecognizerSharedState());
    }
    public AlgebraicExpressionWalker(TreeNodeStream input, RecognizerSharedState state) {
        super(input, state);
    }

    public String[] getTokenNames() { return AlgebraicExpressionWalker.tokenNames; }
    public String getGrammarFileName() { return "/tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g"; }


        public static PolynomialOperation createVariable( String name, boolean hasParentheses )
        {
            try
            {
                return new PolynomialVariable( PolynomialVariable.Var.valueOf( name ), hasParentheses );
            }
            catch( Exception e )
            {
                return new DoubleVariable( name, hasParentheses );
            }
        }

        public static int createInteger( String text )
        {
            try
            {
                return Integer.parseInt( text );
            }
            catch( NumberFormatException nfe )
            {
                return 0;
            }
        }



    // $ANTLR start "start"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:55:1: start returns [ PolynomialOperation op ] : e= expr ;
    public final PolynomialOperation start() throws RecognitionException {
        PolynomialOperation op = null;


        AlgebraicExpressionWalker.expr_return e =null;


        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:56:5: (e= expr )
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:56:7: e= expr
            {
            pushFollow(FOLLOW_expr_in_start58);
            e=expr();

            state._fsp--;


             op = (e!=null?e.op:null); 

            }

        }
        catch (RecognitionException re) {
            reportError(re);
            recover(input,re);
        }

        finally {
        	// do for sure before leaving
        }
        return op;
    }
    // $ANTLR end "start"


    public static class expr_return extends TreeRuleReturnScope {
        public PolynomialOperation op;
        public Integer decimal;
    };


    // $ANTLR start "expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:59:1: expr returns [ PolynomialOperation op, Integer decimal ] : ( (p= PARENTHESES )? ^( PLUS e1= expr e2= expr ) | (p= PARENTHESES )? ^( MINUS e1= expr (e2= expr )? ) | (p= PARENTHESES )? ^( MULT e1= expr e2= expr ) | (p= PARENTHESES )? ^( DIV e1= expr e2= expr ) | (p= PARENTHESES )? ^( POW e1= expr e2= expr ) | (p= PARENTHESES )? ^(id= IDENTIFIER e1= expr (e2= expr )? ) |pe= primary_expr );
    public final AlgebraicExpressionWalker.expr_return expr() throws RecognitionException {
        AlgebraicExpressionWalker.expr_return retval = new AlgebraicExpressionWalker.expr_return();
        retval.start = input.LT(1);


        CommonTree p=null;
        CommonTree id=null;
        AlgebraicExpressionWalker.expr_return e1 =null;

        AlgebraicExpressionWalker.expr_return e2 =null;

        AlgebraicExpressionWalker.primary_expr_return pe =null;


        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:60:2: ( (p= PARENTHESES )? ^( PLUS e1= expr e2= expr ) | (p= PARENTHESES )? ^( MINUS e1= expr (e2= expr )? ) | (p= PARENTHESES )? ^( MULT e1= expr e2= expr ) | (p= PARENTHESES )? ^( DIV e1= expr e2= expr ) | (p= PARENTHESES )? ^( POW e1= expr e2= expr ) | (p= PARENTHESES )? ^(id= IDENTIFIER e1= expr (e2= expr )? ) |pe= primary_expr )
            int alt9=7;
            switch ( input.LA(1) ) {
            case PARENTHESES:
                {
                switch ( input.LA(2) ) {
                case PLUS:
                    {
                    alt9=1;
                    }
                    break;
                case MINUS:
                    {
                    alt9=2;
                    }
                    break;
                case MULT:
                    {
                    alt9=3;
                    }
                    break;
                case DIV:
                    {
                    alt9=4;
                    }
                    break;
                case POW:
                    {
                    alt9=5;
                    }
                    break;
                case IDENTIFIER:
                    {
                    int LA9_7 = input.LA(3);

                    if ( (LA9_7==DOWN) ) {
                        alt9=6;
                    }
                    else if ( (LA9_7==EOF||(LA9_7 >= UP && LA9_7 <= DECIMAL_LITERAL)||LA9_7==DIV||(LA9_7 >= FLOATING_POINT_LITERAL && LA9_7 <= IDENTIFIER)||(LA9_7 >= MINUS && LA9_7 <= POW)) ) {
                        alt9=7;
                    }
                    else {
                        NoViableAltException nvae =
                            new NoViableAltException("", 9, 7, input);

                        throw nvae;

                    }
                    }
                    break;
                case DECIMAL_LITERAL:
                case FLOATING_POINT_LITERAL:
                    {
                    alt9=7;
                    }
                    break;
                default:
                    NoViableAltException nvae =
                        new NoViableAltException("", 9, 1, input);

                    throw nvae;

                }

                }
                break;
            case PLUS:
                {
                alt9=1;
                }
                break;
            case MINUS:
                {
                alt9=2;
                }
                break;
            case MULT:
                {
                alt9=3;
                }
                break;
            case DIV:
                {
                alt9=4;
                }
                break;
            case POW:
                {
                alt9=5;
                }
                break;
            case IDENTIFIER:
                {
                int LA9_7 = input.LA(2);

                if ( (LA9_7==DOWN) ) {
                    alt9=6;
                }
                else if ( (LA9_7==EOF||(LA9_7 >= UP && LA9_7 <= DECIMAL_LITERAL)||LA9_7==DIV||(LA9_7 >= FLOATING_POINT_LITERAL && LA9_7 <= IDENTIFIER)||(LA9_7 >= MINUS && LA9_7 <= POW)) ) {
                    alt9=7;
                }
                else {
                    NoViableAltException nvae =
                        new NoViableAltException("", 9, 7, input);

                    throw nvae;

                }
                }
                break;
            case DECIMAL_LITERAL:
            case FLOATING_POINT_LITERAL:
                {
                alt9=7;
                }
                break;
            default:
                NoViableAltException nvae =
                    new NoViableAltException("", 9, 0, input);

                throw nvae;

            }

            switch (alt9) {
                case 1 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:60:5: (p= PARENTHESES )? ^( PLUS e1= expr e2= expr )
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:60:5: (p= PARENTHESES )?
                    int alt1=2;
                    int LA1_0 = input.LA(1);

                    if ( (LA1_0==PARENTHESES) ) {
                        alt1=1;
                    }
                    switch (alt1) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:60:7: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_expr85); 

                            }
                            break;

                    }


                    match(input,PLUS,FOLLOW_PLUS_in_expr92); 

                    match(input, Token.DOWN, null); 
                    pushFollow(FOLLOW_expr_in_expr98);
                    e1=expr();

                    state._fsp--;


                    pushFollow(FOLLOW_expr_in_expr104);
                    e2=expr();

                    state._fsp--;


                    match(input, Token.UP, null); 



                                    try
                                    {
                                        retval.op = new DoubleBinaryOperation( DoubleBinaryOperation.Op.add, ( DoubleOperation ) (e1!=null?e1.op:null), ( DoubleOperation ) (e2!=null?e2.op:null), p != null );
                                    }
                                    catch( ClassCastException cce )
                                    {
                                        retval.op = new PolynomialAddition( (e1!=null?e1.op:null), (e2!=null?e2.op:null), p != null );
                                    }
                                

                    }
                    break;
                case 2 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:71:11: (p= PARENTHESES )? ^( MINUS e1= expr (e2= expr )? )
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:71:11: (p= PARENTHESES )?
                    int alt2=2;
                    int LA2_0 = input.LA(1);

                    if ( (LA2_0==PARENTHESES) ) {
                        alt2=1;
                    }
                    switch (alt2) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:71:13: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_expr138); 

                            }
                            break;

                    }


                    match(input,MINUS,FOLLOW_MINUS_in_expr145); 

                    match(input, Token.DOWN, null); 
                    pushFollow(FOLLOW_expr_in_expr151);
                    e1=expr();

                    state._fsp--;


                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:71:51: (e2= expr )?
                    int alt3=2;
                    int LA3_0 = input.LA(1);

                    if ( (LA3_0==DECIMAL_LITERAL||LA3_0==DIV||(LA3_0 >= FLOATING_POINT_LITERAL && LA3_0 <= IDENTIFIER)||(LA3_0 >= MINUS && LA3_0 <= POW)) ) {
                        alt3=1;
                    }
                    switch (alt3) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:71:53: e2= expr
                            {
                            pushFollow(FOLLOW_expr_in_expr159);
                            e2=expr();

                            state._fsp--;


                            }
                            break;

                    }


                    match(input, Token.UP, null); 



                                    if( e2 != null )
                                    {
                                        // subtraction
                                        try
                                        {
                                            retval.op = new DoubleBinaryOperation( DoubleBinaryOperation.Op.sub, ( DoubleOperation ) (e1!=null?e1.op:null), ( DoubleOperation ) (e2!=null?e2.op:null), p != null );
                                        }
                                        catch( ClassCastException cce )
                                        {
                                            retval.op = new PolynomialSubtraction( (e1!=null?e1.op:null), (e2!=null?e2.op:null), p != null );
                                        }
                                    }
                                    else
                                    {
                                        try
                                        {
                                            retval.op = new DoubleUnaryOperation( DoubleUnaryOperation.Op.neg, ( DoubleOperation ) (e1!=null?e1.op:null), p != null );
                                        }
                                        catch( ClassCastException cce )
                                        {
                                            retval.op = new PolynomialNegation( (e1!=null?e1.op:null), p != null );
                                        }
                                    }
                                

                    }
                    break;
                case 3 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:97:11: (p= PARENTHESES )? ^( MULT e1= expr e2= expr )
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:97:11: (p= PARENTHESES )?
                    int alt4=2;
                    int LA4_0 = input.LA(1);

                    if ( (LA4_0==PARENTHESES) ) {
                        alt4=1;
                    }
                    switch (alt4) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:97:13: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_expr197); 

                            }
                            break;

                    }


                    match(input,MULT,FOLLOW_MULT_in_expr204); 

                    match(input, Token.DOWN, null); 
                    pushFollow(FOLLOW_expr_in_expr210);
                    e1=expr();

                    state._fsp--;


                    pushFollow(FOLLOW_expr_in_expr216);
                    e2=expr();

                    state._fsp--;


                    match(input, Token.UP, null); 



                                    try
                                    {
                                        retval.op = new DoubleBinaryOperation( DoubleBinaryOperation.Op.mult, ( DoubleOperation ) (e1!=null?e1.op:null), ( DoubleOperation ) (e2!=null?e2.op:null) );
                                    }
                                    catch( ClassCastException cce )
                                    {
                                        retval.op = new PolynomialMultiplication( (e1!=null?e1.op:null), (e2!=null?e2.op:null), p != null );
                                    }
                                

                    }
                    break;
                case 4 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:108:11: (p= PARENTHESES )? ^( DIV e1= expr e2= expr )
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:108:11: (p= PARENTHESES )?
                    int alt5=2;
                    int LA5_0 = input.LA(1);

                    if ( (LA5_0==PARENTHESES) ) {
                        alt5=1;
                    }
                    switch (alt5) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:108:13: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_expr250); 

                            }
                            break;

                    }


                    match(input,DIV,FOLLOW_DIV_in_expr257); 

                    match(input, Token.DOWN, null); 
                    pushFollow(FOLLOW_expr_in_expr263);
                    e1=expr();

                    state._fsp--;


                    pushFollow(FOLLOW_expr_in_expr269);
                    e2=expr();

                    state._fsp--;


                    match(input, Token.UP, null); 



                                    try
                                    {
                                        retval.op = new DoubleBinaryOperation( DoubleBinaryOperation.Op.div, ( DoubleOperation ) (e1!=null?e1.op:null), ( DoubleOperation ) (e2!=null?e2.op:null), p != null );
                                    }
                                    catch( ClassCastException cce1 )
                                    {
                                        try
                                        {
                                            retval.op = new PolynomialDoubleDivision( (e1!=null?e1.op:null), ( DoubleOperation ) (e2!=null?e2.op:null), p != null );
                                        }
                                        catch( ClassCastException cce2 )
                                        {
                                            throw new RecognitionException();
                                        }
                                    }
                                

                    }
                    break;
                case 5 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:126:11: (p= PARENTHESES )? ^( POW e1= expr e2= expr )
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:126:11: (p= PARENTHESES )?
                    int alt6=2;
                    int LA6_0 = input.LA(1);

                    if ( (LA6_0==PARENTHESES) ) {
                        alt6=1;
                    }
                    switch (alt6) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:126:13: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_expr303); 

                            }
                            break;

                    }


                    match(input,POW,FOLLOW_POW_in_expr310); 

                    match(input, Token.DOWN, null); 
                    pushFollow(FOLLOW_expr_in_expr316);
                    e1=expr();

                    state._fsp--;


                    pushFollow(FOLLOW_expr_in_expr322);
                    e2=expr();

                    state._fsp--;


                    match(input, Token.UP, null); 



                                    try
                                    {
                                        retval.op = new DoubleBinaryOperation( DoubleBinaryOperation.Op.pow, ( DoubleOperation ) (e1!=null?e1.op:null), ( DoubleOperation ) (e2!=null?e2.op:null), p != null );
                                    }
                                    catch( ClassCastException cce )
                                    {
                                        if( (e2!=null?e2.decimal:null) == null )
                                        {
                                            throw new RecognitionException();
                                        }
                                        else
                                        {
                                            retval.op = new PolynomialPower( (e1!=null?e1.op:null), (e2!=null?e2.decimal:null), p != null );
                                        }
                                    }
                                

                    }
                    break;
                case 6 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:144:11: (p= PARENTHESES )? ^(id= IDENTIFIER e1= expr (e2= expr )? )
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:144:11: (p= PARENTHESES )?
                    int alt7=2;
                    int LA7_0 = input.LA(1);

                    if ( (LA7_0==PARENTHESES) ) {
                        alt7=1;
                    }
                    switch (alt7) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:144:13: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_expr356); 

                            }
                            break;

                    }


                    id=(CommonTree)match(input,IDENTIFIER,FOLLOW_IDENTIFIER_in_expr367); 

                    match(input, Token.DOWN, null); 
                    pushFollow(FOLLOW_expr_in_expr373);
                    e1=expr();

                    state._fsp--;


                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:144:61: (e2= expr )?
                    int alt8=2;
                    int LA8_0 = input.LA(1);

                    if ( (LA8_0==DECIMAL_LITERAL||LA8_0==DIV||(LA8_0 >= FLOATING_POINT_LITERAL && LA8_0 <= IDENTIFIER)||(LA8_0 >= MINUS && LA8_0 <= POW)) ) {
                        alt8=1;
                    }
                    switch (alt8) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:144:63: e2= expr
                            {
                            pushFollow(FOLLOW_expr_in_expr381);
                            e2=expr();

                            state._fsp--;


                            }
                            break;

                    }


                    match(input, Token.UP, null); 



                                    if( e2 != null )
                                    {
                                        try
                                        {
                                            retval.op = new DoubleBinaryOperation( DoubleBinaryOperation.Op.valueOf( (id!=null?id.getText():null) ), ( DoubleOperation ) (e1!=null?e1.op:null), ( DoubleOperation ) (e2!=null?e2.op:null), p != null );
                                        }
                                        catch( ClassCastException cce )
                                        {
                                            throw new RecognitionException();
                                        }
                                        catch( IllegalArgumentException iae )
                                        {
                                            throw new RecognitionException();
                                        }
                                    }
                                    else
                                    {
                                        try
                                        {
                                            retval.op = new DoubleUnaryOperation( DoubleUnaryOperation.Op.valueOf( (id!=null?id.getText():null) ), ( DoubleOperation ) (e1!=null?e1.op:null), p != null );
                                        }
                                        catch( ClassCastException cce )
                                        {
                                            throw new RecognitionException();
                                        }
                                        catch( IllegalArgumentException iae )
                                        {
                                            throw new RecognitionException();
                                        }
                                    }
                                

                    }
                    break;
                case 7 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:177:11: pe= primary_expr
                    {
                    pushFollow(FOLLOW_primary_expr_in_expr416);
                    pe=primary_expr();

                    state._fsp--;


                     retval.op = (pe!=null?pe.op:null); retval.decimal = pe.decimal; 

                    }
                    break;

            }
        }
        catch (RecognitionException re) {
            reportError(re);
            recover(input,re);
        }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "expr"


    public static class primary_expr_return extends TreeRuleReturnScope {
        public PolynomialOperation op;
        public Integer decimal;
    };


    // $ANTLR start "primary_expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:180:1: primary_expr returns [ PolynomialOperation op, Integer decimal ] : ( (p= PARENTHESES )? i= DECIMAL_LITERAL | (p= PARENTHESES )? f= FLOATING_POINT_LITERAL | (p= PARENTHESES )? id= IDENTIFIER );
    public final AlgebraicExpressionWalker.primary_expr_return primary_expr() throws RecognitionException {
        AlgebraicExpressionWalker.primary_expr_return retval = new AlgebraicExpressionWalker.primary_expr_return();
        retval.start = input.LT(1);


        CommonTree p=null;
        CommonTree i=null;
        CommonTree f=null;
        CommonTree id=null;

        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:181:2: ( (p= PARENTHESES )? i= DECIMAL_LITERAL | (p= PARENTHESES )? f= FLOATING_POINT_LITERAL | (p= PARENTHESES )? id= IDENTIFIER )
            int alt13=3;
            switch ( input.LA(1) ) {
            case PARENTHESES:
                {
                switch ( input.LA(2) ) {
                case DECIMAL_LITERAL:
                    {
                    alt13=1;
                    }
                    break;
                case FLOATING_POINT_LITERAL:
                    {
                    alt13=2;
                    }
                    break;
                case IDENTIFIER:
                    {
                    alt13=3;
                    }
                    break;
                default:
                    NoViableAltException nvae =
                        new NoViableAltException("", 13, 1, input);

                    throw nvae;

                }

                }
                break;
            case DECIMAL_LITERAL:
                {
                alt13=1;
                }
                break;
            case FLOATING_POINT_LITERAL:
                {
                alt13=2;
                }
                break;
            case IDENTIFIER:
                {
                alt13=3;
                }
                break;
            default:
                NoViableAltException nvae =
                    new NoViableAltException("", 13, 0, input);

                throw nvae;

            }

            switch (alt13) {
                case 1 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:181:4: (p= PARENTHESES )? i= DECIMAL_LITERAL
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:181:4: (p= PARENTHESES )?
                    int alt10=2;
                    int LA10_0 = input.LA(1);

                    if ( (LA10_0==PARENTHESES) ) {
                        alt10=1;
                    }
                    switch (alt10) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:181:6: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_primary_expr439); 

                            }
                            break;

                    }


                    i=(CommonTree)match(input,DECIMAL_LITERAL,FOLLOW_DECIMAL_LITERAL_in_primary_expr448); 

                     retval.op = new DoubleValue( (i!=null?i.getText():null), p != null ); retval.decimal = Integer.valueOf( createInteger( (i!=null?i.getText():null) ) ); 

                    }
                    break;
                case 2 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:182:4: (p= PARENTHESES )? f= FLOATING_POINT_LITERAL
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:182:4: (p= PARENTHESES )?
                    int alt11=2;
                    int LA11_0 = input.LA(1);

                    if ( (LA11_0==PARENTHESES) ) {
                        alt11=1;
                    }
                    switch (alt11) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:182:6: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_primary_expr461); 

                            }
                            break;

                    }


                    f=(CommonTree)match(input,FLOATING_POINT_LITERAL,FOLLOW_FLOATING_POINT_LITERAL_in_primary_expr470); 

                     retval.op = new DoubleValue( (f!=null?f.getText():null), p != null ); 

                    }
                    break;
                case 3 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:183:4: (p= PARENTHESES )? id= IDENTIFIER
                    {
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:183:4: (p= PARENTHESES )?
                    int alt12=2;
                    int LA12_0 = input.LA(1);

                    if ( (LA12_0==PARENTHESES) ) {
                        alt12=1;
                    }
                    switch (alt12) {
                        case 1 :
                            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpressionWalker.g:183:6: p= PARENTHESES
                            {
                            p=(CommonTree)match(input,PARENTHESES,FOLLOW_PARENTHESES_in_primary_expr483); 

                            }
                            break;

                    }


                    id=(CommonTree)match(input,IDENTIFIER,FOLLOW_IDENTIFIER_in_primary_expr492); 

                     retval.op = createVariable( (id!=null?id.getText():null), p != null ); 

                    }
                    break;

            }
        }
        catch (RecognitionException re) {
            reportError(re);
            recover(input,re);
        }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "primary_expr"

    // Delegated rules


 

    public static final BitSet FOLLOW_expr_in_start58 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_PARENTHESES_in_expr85 = new BitSet(new long[]{0x0000000000010000L});
    public static final BitSet FOLLOW_PLUS_in_expr92 = new BitSet(new long[]{0x0000000000000004L});
    public static final BitSet FOLLOW_expr_in_expr98 = new BitSet(new long[]{0x000000000003E650L});
    public static final BitSet FOLLOW_expr_in_expr104 = new BitSet(new long[]{0x0000000000000008L});
    public static final BitSet FOLLOW_PARENTHESES_in_expr138 = new BitSet(new long[]{0x0000000000002000L});
    public static final BitSet FOLLOW_MINUS_in_expr145 = new BitSet(new long[]{0x0000000000000004L});
    public static final BitSet FOLLOW_expr_in_expr151 = new BitSet(new long[]{0x000000000003E658L});
    public static final BitSet FOLLOW_expr_in_expr159 = new BitSet(new long[]{0x0000000000000008L});
    public static final BitSet FOLLOW_PARENTHESES_in_expr197 = new BitSet(new long[]{0x0000000000004000L});
    public static final BitSet FOLLOW_MULT_in_expr204 = new BitSet(new long[]{0x0000000000000004L});
    public static final BitSet FOLLOW_expr_in_expr210 = new BitSet(new long[]{0x000000000003E650L});
    public static final BitSet FOLLOW_expr_in_expr216 = new BitSet(new long[]{0x0000000000000008L});
    public static final BitSet FOLLOW_PARENTHESES_in_expr250 = new BitSet(new long[]{0x0000000000000040L});
    public static final BitSet FOLLOW_DIV_in_expr257 = new BitSet(new long[]{0x0000000000000004L});
    public static final BitSet FOLLOW_expr_in_expr263 = new BitSet(new long[]{0x000000000003E650L});
    public static final BitSet FOLLOW_expr_in_expr269 = new BitSet(new long[]{0x0000000000000008L});
    public static final BitSet FOLLOW_PARENTHESES_in_expr303 = new BitSet(new long[]{0x0000000000020000L});
    public static final BitSet FOLLOW_POW_in_expr310 = new BitSet(new long[]{0x0000000000000004L});
    public static final BitSet FOLLOW_expr_in_expr316 = new BitSet(new long[]{0x000000000003E650L});
    public static final BitSet FOLLOW_expr_in_expr322 = new BitSet(new long[]{0x0000000000000008L});
    public static final BitSet FOLLOW_PARENTHESES_in_expr356 = new BitSet(new long[]{0x0000000000000400L});
    public static final BitSet FOLLOW_IDENTIFIER_in_expr367 = new BitSet(new long[]{0x0000000000000004L});
    public static final BitSet FOLLOW_expr_in_expr373 = new BitSet(new long[]{0x000000000003E658L});
    public static final BitSet FOLLOW_expr_in_expr381 = new BitSet(new long[]{0x0000000000000008L});
    public static final BitSet FOLLOW_primary_expr_in_expr416 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_PARENTHESES_in_primary_expr439 = new BitSet(new long[]{0x0000000000000010L});
    public static final BitSet FOLLOW_DECIMAL_LITERAL_in_primary_expr448 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_PARENTHESES_in_primary_expr461 = new BitSet(new long[]{0x0000000000000200L});
    public static final BitSet FOLLOW_FLOATING_POINT_LITERAL_in_primary_expr470 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_PARENTHESES_in_primary_expr483 = new BitSet(new long[]{0x0000000000000400L});
    public static final BitSet FOLLOW_IDENTIFIER_in_primary_expr492 = new BitSet(new long[]{0x0000000000000002L});

}