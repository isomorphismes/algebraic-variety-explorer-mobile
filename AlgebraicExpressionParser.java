// $ANTLR 3.4 /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g 2026-07-26 21:28:06

package de.mfo.jsurf.parser;

import de.mfo.jsurf.algebra.*;


import org.antlr.runtime.*;
import java.util.Stack;
import java.util.List;
import java.util.ArrayList;

import org.antlr.runtime.tree.*;


@SuppressWarnings({"all", "warnings", "unchecked"})
public class AlgebraicExpressionParser extends Parser {
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
    public Parser[] getDelegates() {
        return new Parser[] {};
    }

    // delegators


    public AlgebraicExpressionParser(TokenStream input) {
        this(input, new RecognizerSharedState());
    }
    public AlgebraicExpressionParser(TokenStream input, RecognizerSharedState state) {
        super(input, state);
    }

protected TreeAdaptor adaptor = new CommonTreeAdaptor();

public void setTreeAdaptor(TreeAdaptor adaptor) {
    this.adaptor = adaptor;
}
public TreeAdaptor getTreeAdaptor() {
    return adaptor;
}
    public String[] getTokenNames() { return AlgebraicExpressionParser.tokenNames; }
    public String getGrammarFileName() { return "/tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g"; }


        public static PolynomialOperation parse( String s )
            throws Exception
        {
            // Create a string
            ANTLRStringStream input = new ANTLRStringStream( s );

            // Create an ExprLexer that feeds from that stream
            AlgebraicExpressionLexer lexer = new AlgebraicExpressionLexer( input );

            // Create a stream of tokens fed by the lexer
            CommonTokenStream tokens = new CommonTokenStream( lexer );

            // Create a parser that feeds off the token stream
            AlgebraicExpressionParser parser = new AlgebraicExpressionParser( tokens );

            // Begin parsing at start rule
            AlgebraicExpressionParser.start_return r = parser.start();

            // Create a stream of nodes fed by the parser
            CommonTreeNodeStream nodes = new CommonTreeNodeStream( ( CommonTree ) r.getTree() );

            // Create a tree parser that feeds off the node stream
            AlgebraicExpressionWalker walker = new AlgebraicExpressionWalker( nodes );

            // Begin tree parsing at start rule
            return walker.start();
        }

        protected void mismatch( IntStream input, int ttype, BitSet follow )
            throws RecognitionException
        {
            throw new MismatchedTokenException(ttype, input);
        }

        @Override
        public java.lang.Object recoverFromMismatchedSet( IntStream input, RecognitionException e, BitSet follow )
            throws RecognitionException
        {
            throw e;
        }

        @Override
        protected Object recoverFromMismatchedToken( IntStream input, int ttype, BitSet follow )
            throws RecognitionException
        {
            throw new MismatchedTokenException( ttype, input );
        }


    public static class start_return extends ParserRuleReturnScope {
        Object tree;
        public Object getTree() { return tree; }
    };


    // $ANTLR start "start"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:104:1: start : add_expr EOF !;
    public final AlgebraicExpressionParser.start_return start() throws RecognitionException {
        AlgebraicExpressionParser.start_return retval = new AlgebraicExpressionParser.start_return();
        retval.start = input.LT(1);


        Object root_0 = null;

        Token EOF2=null;
        AlgebraicExpressionParser.add_expr_return add_expr1 =null;


        Object EOF2_tree=null;

        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:105:2: ( add_expr EOF !)
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:105:4: add_expr EOF !
            {
            root_0 = (Object)adaptor.nil();


            pushFollow(FOLLOW_add_expr_in_start138);
            add_expr1=add_expr();

            state._fsp--;

            adaptor.addChild(root_0, add_expr1.getTree());

            EOF2=(Token)match(input,EOF,FOLLOW_EOF_in_start140); 

            }

            retval.stop = input.LT(-1);


            retval.tree = (Object)adaptor.rulePostProcessing(root_0);
            adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);

        }

            catch( RecognitionException e )
            {
                throw e;
            }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "start"


    public static class add_expr_return extends ParserRuleReturnScope {
        Object tree;
        public Object getTree() { return tree; }
    };


    // $ANTLR start "add_expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:108:1: add_expr : mult_expr ( PLUS ^ mult_expr | MINUS ^ mult_expr )* ;
    public final AlgebraicExpressionParser.add_expr_return add_expr() throws RecognitionException {
        AlgebraicExpressionParser.add_expr_return retval = new AlgebraicExpressionParser.add_expr_return();
        retval.start = input.LT(1);


        Object root_0 = null;

        Token PLUS4=null;
        Token MINUS6=null;
        AlgebraicExpressionParser.mult_expr_return mult_expr3 =null;

        AlgebraicExpressionParser.mult_expr_return mult_expr5 =null;

        AlgebraicExpressionParser.mult_expr_return mult_expr7 =null;


        Object PLUS4_tree=null;
        Object MINUS6_tree=null;

        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:109:2: ( mult_expr ( PLUS ^ mult_expr | MINUS ^ mult_expr )* )
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:109:4: mult_expr ( PLUS ^ mult_expr | MINUS ^ mult_expr )*
            {
            root_0 = (Object)adaptor.nil();


            pushFollow(FOLLOW_mult_expr_in_add_expr152);
            mult_expr3=mult_expr();

            state._fsp--;

            adaptor.addChild(root_0, mult_expr3.getTree());

            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:109:14: ( PLUS ^ mult_expr | MINUS ^ mult_expr )*
            loop1:
            do {
                int alt1=3;
                int LA1_0 = input.LA(1);

                if ( (LA1_0==PLUS) ) {
                    alt1=1;
                }
                else if ( (LA1_0==MINUS) ) {
                    alt1=2;
                }


                switch (alt1) {
            	case 1 :
            	    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:109:16: PLUS ^ mult_expr
            	    {
            	    PLUS4=(Token)match(input,PLUS,FOLLOW_PLUS_in_add_expr156); 
            	    PLUS4_tree = 
            	    (Object)adaptor.create(PLUS4)
            	    ;
            	    root_0 = (Object)adaptor.becomeRoot(PLUS4_tree, root_0);


            	    pushFollow(FOLLOW_mult_expr_in_add_expr159);
            	    mult_expr5=mult_expr();

            	    state._fsp--;

            	    adaptor.addChild(root_0, mult_expr5.getTree());

            	    }
            	    break;
            	case 2 :
            	    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:109:34: MINUS ^ mult_expr
            	    {
            	    MINUS6=(Token)match(input,MINUS,FOLLOW_MINUS_in_add_expr163); 
            	    MINUS6_tree = 
            	    (Object)adaptor.create(MINUS6)
            	    ;
            	    root_0 = (Object)adaptor.becomeRoot(MINUS6_tree, root_0);


            	    pushFollow(FOLLOW_mult_expr_in_add_expr166);
            	    mult_expr7=mult_expr();

            	    state._fsp--;

            	    adaptor.addChild(root_0, mult_expr7.getTree());

            	    }
            	    break;

            	default :
            	    break loop1;
                }
            } while (true);


            }

            retval.stop = input.LT(-1);


            retval.tree = (Object)adaptor.rulePostProcessing(root_0);
            adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);

        }

            catch( RecognitionException e )
            {
                throw e;
            }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "add_expr"


    public static class mult_expr_return extends ParserRuleReturnScope {
        Object tree;
        public Object getTree() { return tree; }
    };


    // $ANTLR start "mult_expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:112:1: mult_expr : neg_expr ( MULT ^ neg_expr | DIV ^ neg_expr )* ;
    public final AlgebraicExpressionParser.mult_expr_return mult_expr() throws RecognitionException {
        AlgebraicExpressionParser.mult_expr_return retval = new AlgebraicExpressionParser.mult_expr_return();
        retval.start = input.LT(1);


        Object root_0 = null;

        Token MULT9=null;
        Token DIV11=null;
        AlgebraicExpressionParser.neg_expr_return neg_expr8 =null;

        AlgebraicExpressionParser.neg_expr_return neg_expr10 =null;

        AlgebraicExpressionParser.neg_expr_return neg_expr12 =null;


        Object MULT9_tree=null;
        Object DIV11_tree=null;

        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:113:2: ( neg_expr ( MULT ^ neg_expr | DIV ^ neg_expr )* )
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:113:4: neg_expr ( MULT ^ neg_expr | DIV ^ neg_expr )*
            {
            root_0 = (Object)adaptor.nil();


            pushFollow(FOLLOW_neg_expr_in_mult_expr180);
            neg_expr8=neg_expr();

            state._fsp--;

            adaptor.addChild(root_0, neg_expr8.getTree());

            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:113:13: ( MULT ^ neg_expr | DIV ^ neg_expr )*
            loop2:
            do {
                int alt2=3;
                int LA2_0 = input.LA(1);

                if ( (LA2_0==MULT) ) {
                    alt2=1;
                }
                else if ( (LA2_0==DIV) ) {
                    alt2=2;
                }


                switch (alt2) {
            	case 1 :
            	    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:113:15: MULT ^ neg_expr
            	    {
            	    MULT9=(Token)match(input,MULT,FOLLOW_MULT_in_mult_expr184); 
            	    MULT9_tree = 
            	    (Object)adaptor.create(MULT9)
            	    ;
            	    root_0 = (Object)adaptor.becomeRoot(MULT9_tree, root_0);


            	    pushFollow(FOLLOW_neg_expr_in_mult_expr187);
            	    neg_expr10=neg_expr();

            	    state._fsp--;

            	    adaptor.addChild(root_0, neg_expr10.getTree());

            	    }
            	    break;
            	case 2 :
            	    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:113:32: DIV ^ neg_expr
            	    {
            	    DIV11=(Token)match(input,DIV,FOLLOW_DIV_in_mult_expr191); 
            	    DIV11_tree = 
            	    (Object)adaptor.create(DIV11)
            	    ;
            	    root_0 = (Object)adaptor.becomeRoot(DIV11_tree, root_0);


            	    pushFollow(FOLLOW_neg_expr_in_mult_expr194);
            	    neg_expr12=neg_expr();

            	    state._fsp--;

            	    adaptor.addChild(root_0, neg_expr12.getTree());

            	    }
            	    break;

            	default :
            	    break loop2;
                }
            } while (true);


            }

            retval.stop = input.LT(-1);


            retval.tree = (Object)adaptor.rulePostProcessing(root_0);
            adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);

        }

            catch( RecognitionException e )
            {
                throw e;
            }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "mult_expr"


    public static class neg_expr_return extends ParserRuleReturnScope {
        Object tree;
        public Object getTree() { return tree; }
    };


    // $ANTLR start "neg_expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:116:1: neg_expr : ( MINUS ^ pow_expr | pow_expr );
    public final AlgebraicExpressionParser.neg_expr_return neg_expr() throws RecognitionException {
        AlgebraicExpressionParser.neg_expr_return retval = new AlgebraicExpressionParser.neg_expr_return();
        retval.start = input.LT(1);


        Object root_0 = null;

        Token MINUS13=null;
        AlgebraicExpressionParser.pow_expr_return pow_expr14 =null;

        AlgebraicExpressionParser.pow_expr_return pow_expr15 =null;


        Object MINUS13_tree=null;

        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:117:9: ( MINUS ^ pow_expr | pow_expr )
            int alt3=2;
            int LA3_0 = input.LA(1);

            if ( (LA3_0==MINUS) ) {
                alt3=1;
            }
            else if ( (LA3_0==DECIMAL_LITERAL||(LA3_0 >= FLOATING_POINT_LITERAL && LA3_0 <= IDENTIFIER)||LA3_0==LPAR) ) {
                alt3=2;
            }
            else {
                NoViableAltException nvae =
                    new NoViableAltException("", 3, 0, input);

                throw nvae;

            }
            switch (alt3) {
                case 1 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:117:11: MINUS ^ pow_expr
                    {
                    root_0 = (Object)adaptor.nil();


                    MINUS13=(Token)match(input,MINUS,FOLLOW_MINUS_in_neg_expr215); 
                    MINUS13_tree = 
                    (Object)adaptor.create(MINUS13)
                    ;
                    root_0 = (Object)adaptor.becomeRoot(MINUS13_tree, root_0);


                    pushFollow(FOLLOW_pow_expr_in_neg_expr218);
                    pow_expr14=pow_expr();

                    state._fsp--;

                    adaptor.addChild(root_0, pow_expr14.getTree());

                    }
                    break;
                case 2 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:118:11: pow_expr
                    {
                    root_0 = (Object)adaptor.nil();


                    pushFollow(FOLLOW_pow_expr_in_neg_expr230);
                    pow_expr15=pow_expr();

                    state._fsp--;

                    adaptor.addChild(root_0, pow_expr15.getTree());

                    }
                    break;

            }
            retval.stop = input.LT(-1);


            retval.tree = (Object)adaptor.rulePostProcessing(root_0);
            adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);

        }

            catch( RecognitionException e )
            {
                throw e;
            }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "neg_expr"


    public static class pow_expr_return extends ParserRuleReturnScope {
        Object tree;
        public Object getTree() { return tree; }
    };


    // $ANTLR start "pow_expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:121:1: pow_expr : unary_expr ( POW ^ pow_expr )? ;
    public final AlgebraicExpressionParser.pow_expr_return pow_expr() throws RecognitionException {
        AlgebraicExpressionParser.pow_expr_return retval = new AlgebraicExpressionParser.pow_expr_return();
        retval.start = input.LT(1);


        Object root_0 = null;

        Token POW17=null;
        AlgebraicExpressionParser.unary_expr_return unary_expr16 =null;

        AlgebraicExpressionParser.pow_expr_return pow_expr18 =null;


        Object POW17_tree=null;

        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:122:2: ( unary_expr ( POW ^ pow_expr )? )
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:122:4: unary_expr ( POW ^ pow_expr )?
            {
            root_0 = (Object)adaptor.nil();


            pushFollow(FOLLOW_unary_expr_in_pow_expr248);
            unary_expr16=unary_expr();

            state._fsp--;

            adaptor.addChild(root_0, unary_expr16.getTree());

            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:122:15: ( POW ^ pow_expr )?
            int alt4=2;
            int LA4_0 = input.LA(1);

            if ( (LA4_0==POW) ) {
                alt4=1;
            }
            switch (alt4) {
                case 1 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:122:17: POW ^ pow_expr
                    {
                    POW17=(Token)match(input,POW,FOLLOW_POW_in_pow_expr252); 
                    POW17_tree = 
                    (Object)adaptor.create(POW17)
                    ;
                    root_0 = (Object)adaptor.becomeRoot(POW17_tree, root_0);


                    pushFollow(FOLLOW_pow_expr_in_pow_expr255);
                    pow_expr18=pow_expr();

                    state._fsp--;

                    adaptor.addChild(root_0, pow_expr18.getTree());

                    }
                    break;

            }


            }

            retval.stop = input.LT(-1);


            retval.tree = (Object)adaptor.rulePostProcessing(root_0);
            adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);

        }

            catch( RecognitionException e )
            {
                throw e;
            }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "pow_expr"


    public static class unary_expr_return extends ParserRuleReturnScope {
        Object tree;
        public Object getTree() { return tree; }
    };


    // $ANTLR start "unary_expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:125:1: unary_expr : ( primary_expr | IDENTIFIER LPAR add_expr RPAR -> ^( IDENTIFIER PARENTHESES add_expr ) );
    public final AlgebraicExpressionParser.unary_expr_return unary_expr() throws RecognitionException {
        AlgebraicExpressionParser.unary_expr_return retval = new AlgebraicExpressionParser.unary_expr_return();
        retval.start = input.LT(1);


        Object root_0 = null;

        Token IDENTIFIER20=null;
        Token LPAR21=null;
        Token RPAR23=null;
        AlgebraicExpressionParser.primary_expr_return primary_expr19 =null;

        AlgebraicExpressionParser.add_expr_return add_expr22 =null;


        Object IDENTIFIER20_tree=null;
        Object LPAR21_tree=null;
        Object RPAR23_tree=null;
        RewriteRuleTokenStream stream_LPAR=new RewriteRuleTokenStream(adaptor,"token LPAR");
        RewriteRuleTokenStream stream_RPAR=new RewriteRuleTokenStream(adaptor,"token RPAR");
        RewriteRuleTokenStream stream_IDENTIFIER=new RewriteRuleTokenStream(adaptor,"token IDENTIFIER");
        RewriteRuleSubtreeStream stream_add_expr=new RewriteRuleSubtreeStream(adaptor,"rule add_expr");
        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:126:9: ( primary_expr | IDENTIFIER LPAR add_expr RPAR -> ^( IDENTIFIER PARENTHESES add_expr ) )
            int alt5=2;
            int LA5_0 = input.LA(1);

            if ( (LA5_0==DECIMAL_LITERAL||LA5_0==FLOATING_POINT_LITERAL||LA5_0==LPAR) ) {
                alt5=1;
            }
            else if ( (LA5_0==IDENTIFIER) ) {
                int LA5_2 = input.LA(2);

                if ( (LA5_2==LPAR) ) {
                    alt5=2;
                }
                else if ( (LA5_2==EOF||LA5_2==DIV||(LA5_2 >= MINUS && LA5_2 <= MULT)||(LA5_2 >= PLUS && LA5_2 <= RPAR)) ) {
                    alt5=1;
                }
                else {
                    NoViableAltException nvae =
                        new NoViableAltException("", 5, 2, input);

                    throw nvae;

                }
            }
            else {
                NoViableAltException nvae =
                    new NoViableAltException("", 5, 0, input);

                throw nvae;

            }
            switch (alt5) {
                case 1 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:126:11: primary_expr
                    {
                    root_0 = (Object)adaptor.nil();


                    pushFollow(FOLLOW_primary_expr_in_unary_expr276);
                    primary_expr19=primary_expr();

                    state._fsp--;

                    adaptor.addChild(root_0, primary_expr19.getTree());

                    }
                    break;
                case 2 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:127:4: IDENTIFIER LPAR add_expr RPAR
                    {
                    IDENTIFIER20=(Token)match(input,IDENTIFIER,FOLLOW_IDENTIFIER_in_unary_expr281);  
                    stream_IDENTIFIER.add(IDENTIFIER20);


                    LPAR21=(Token)match(input,LPAR,FOLLOW_LPAR_in_unary_expr283);  
                    stream_LPAR.add(LPAR21);


                    pushFollow(FOLLOW_add_expr_in_unary_expr285);
                    add_expr22=add_expr();

                    state._fsp--;

                    stream_add_expr.add(add_expr22.getTree());

                    RPAR23=(Token)match(input,RPAR,FOLLOW_RPAR_in_unary_expr287);  
                    stream_RPAR.add(RPAR23);


                    // AST REWRITE
                    // elements: IDENTIFIER, add_expr
                    // token labels: 
                    // rule labels: retval
                    // token list labels: 
                    // rule list labels: 
                    // wildcard labels: 
                    retval.tree = root_0;
                    RewriteRuleSubtreeStream stream_retval=new RewriteRuleSubtreeStream(adaptor,"rule retval",retval!=null?retval.tree:null);

                    root_0 = (Object)adaptor.nil();
                    // 127:34: -> ^( IDENTIFIER PARENTHESES add_expr )
                    {
                        // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:127:37: ^( IDENTIFIER PARENTHESES add_expr )
                        {
                        Object root_1 = (Object)adaptor.nil();
                        root_1 = (Object)adaptor.becomeRoot(
                        stream_IDENTIFIER.nextNode()
                        , root_1);

                        adaptor.addChild(root_1, 
                        (Object)adaptor.create(PARENTHESES, "PARENTHESES")
                        );

                        adaptor.addChild(root_1, stream_add_expr.nextTree());

                        adaptor.addChild(root_0, root_1);
                        }

                    }


                    retval.tree = root_0;

                    }
                    break;

            }
            retval.stop = input.LT(-1);


            retval.tree = (Object)adaptor.rulePostProcessing(root_0);
            adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);

        }

            catch( RecognitionException e )
            {
                throw e;
            }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "unary_expr"


    public static class primary_expr_return extends ParserRuleReturnScope {
        Object tree;
        public Object getTree() { return tree; }
    };


    // $ANTLR start "primary_expr"
    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:130:1: primary_expr : ( DECIMAL_LITERAL | FLOATING_POINT_LITERAL | IDENTIFIER | LPAR add_expr RPAR -> PARENTHESES add_expr );
    public final AlgebraicExpressionParser.primary_expr_return primary_expr() throws RecognitionException {
        AlgebraicExpressionParser.primary_expr_return retval = new AlgebraicExpressionParser.primary_expr_return();
        retval.start = input.LT(1);


        Object root_0 = null;

        Token DECIMAL_LITERAL24=null;
        Token FLOATING_POINT_LITERAL25=null;
        Token IDENTIFIER26=null;
        Token LPAR27=null;
        Token RPAR29=null;
        AlgebraicExpressionParser.add_expr_return add_expr28 =null;


        Object DECIMAL_LITERAL24_tree=null;
        Object FLOATING_POINT_LITERAL25_tree=null;
        Object IDENTIFIER26_tree=null;
        Object LPAR27_tree=null;
        Object RPAR29_tree=null;
        RewriteRuleTokenStream stream_LPAR=new RewriteRuleTokenStream(adaptor,"token LPAR");
        RewriteRuleTokenStream stream_RPAR=new RewriteRuleTokenStream(adaptor,"token RPAR");
        RewriteRuleSubtreeStream stream_add_expr=new RewriteRuleSubtreeStream(adaptor,"rule add_expr");
        try {
            // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:131:2: ( DECIMAL_LITERAL | FLOATING_POINT_LITERAL | IDENTIFIER | LPAR add_expr RPAR -> PARENTHESES add_expr )
            int alt6=4;
            switch ( input.LA(1) ) {
            case DECIMAL_LITERAL:
                {
                alt6=1;
                }
                break;
            case FLOATING_POINT_LITERAL:
                {
                alt6=2;
                }
                break;
            case IDENTIFIER:
                {
                alt6=3;
                }
                break;
            case LPAR:
                {
                alt6=4;
                }
                break;
            default:
                NoViableAltException nvae =
                    new NoViableAltException("", 6, 0, input);

                throw nvae;

            }

            switch (alt6) {
                case 1 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:131:4: DECIMAL_LITERAL
                    {
                    root_0 = (Object)adaptor.nil();


                    DECIMAL_LITERAL24=(Token)match(input,DECIMAL_LITERAL,FOLLOW_DECIMAL_LITERAL_in_primary_expr308); 
                    DECIMAL_LITERAL24_tree = 
                    (Object)adaptor.create(DECIMAL_LITERAL24)
                    ;
                    adaptor.addChild(root_0, DECIMAL_LITERAL24_tree);


                    }
                    break;
                case 2 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:132:4: FLOATING_POINT_LITERAL
                    {
                    root_0 = (Object)adaptor.nil();


                    FLOATING_POINT_LITERAL25=(Token)match(input,FLOATING_POINT_LITERAL,FOLLOW_FLOATING_POINT_LITERAL_in_primary_expr313); 
                    FLOATING_POINT_LITERAL25_tree = 
                    (Object)adaptor.create(FLOATING_POINT_LITERAL25)
                    ;
                    adaptor.addChild(root_0, FLOATING_POINT_LITERAL25_tree);


                    }
                    break;
                case 3 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:133:4: IDENTIFIER
                    {
                    root_0 = (Object)adaptor.nil();


                    IDENTIFIER26=(Token)match(input,IDENTIFIER,FOLLOW_IDENTIFIER_in_primary_expr318); 
                    IDENTIFIER26_tree = 
                    (Object)adaptor.create(IDENTIFIER26)
                    ;
                    adaptor.addChild(root_0, IDENTIFIER26_tree);


                    }
                    break;
                case 4 :
                    // /tmp/jsurf-parser-fZJEcN/AlgebraicExpression.g:134:4: LPAR add_expr RPAR
                    {
                    LPAR27=(Token)match(input,LPAR,FOLLOW_LPAR_in_primary_expr323);  
                    stream_LPAR.add(LPAR27);


                    pushFollow(FOLLOW_add_expr_in_primary_expr325);
                    add_expr28=add_expr();

                    state._fsp--;

                    stream_add_expr.add(add_expr28.getTree());

                    RPAR29=(Token)match(input,RPAR,FOLLOW_RPAR_in_primary_expr327);  
                    stream_RPAR.add(RPAR29);


                    // AST REWRITE
                    // elements: add_expr
                    // token labels: 
                    // rule labels: retval
                    // token list labels: 
                    // rule list labels: 
                    // wildcard labels: 
                    retval.tree = root_0;
                    RewriteRuleSubtreeStream stream_retval=new RewriteRuleSubtreeStream(adaptor,"rule retval",retval!=null?retval.tree:null);

                    root_0 = (Object)adaptor.nil();
                    // 134:23: -> PARENTHESES add_expr
                    {
                        adaptor.addChild(root_0, 
                        (Object)adaptor.create(PARENTHESES, "PARENTHESES")
                        );

                        adaptor.addChild(root_0, stream_add_expr.nextTree());

                    }


                    retval.tree = root_0;

                    }
                    break;

            }
            retval.stop = input.LT(-1);


            retval.tree = (Object)adaptor.rulePostProcessing(root_0);
            adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);

        }

            catch( RecognitionException e )
            {
                throw e;
            }

        finally {
        	// do for sure before leaving
        }
        return retval;
    }
    // $ANTLR end "primary_expr"

    // Delegated rules


 

    public static final BitSet FOLLOW_add_expr_in_start138 = new BitSet(new long[]{0x0000000000000000L});
    public static final BitSet FOLLOW_EOF_in_start140 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_mult_expr_in_add_expr152 = new BitSet(new long[]{0x0000000000012002L});
    public static final BitSet FOLLOW_PLUS_in_add_expr156 = new BitSet(new long[]{0x0000000000003610L});
    public static final BitSet FOLLOW_mult_expr_in_add_expr159 = new BitSet(new long[]{0x0000000000012002L});
    public static final BitSet FOLLOW_MINUS_in_add_expr163 = new BitSet(new long[]{0x0000000000003610L});
    public static final BitSet FOLLOW_mult_expr_in_add_expr166 = new BitSet(new long[]{0x0000000000012002L});
    public static final BitSet FOLLOW_neg_expr_in_mult_expr180 = new BitSet(new long[]{0x0000000000004042L});
    public static final BitSet FOLLOW_MULT_in_mult_expr184 = new BitSet(new long[]{0x0000000000003610L});
    public static final BitSet FOLLOW_neg_expr_in_mult_expr187 = new BitSet(new long[]{0x0000000000004042L});
    public static final BitSet FOLLOW_DIV_in_mult_expr191 = new BitSet(new long[]{0x0000000000003610L});
    public static final BitSet FOLLOW_neg_expr_in_mult_expr194 = new BitSet(new long[]{0x0000000000004042L});
    public static final BitSet FOLLOW_MINUS_in_neg_expr215 = new BitSet(new long[]{0x0000000000001610L});
    public static final BitSet FOLLOW_pow_expr_in_neg_expr218 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_pow_expr_in_neg_expr230 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_unary_expr_in_pow_expr248 = new BitSet(new long[]{0x0000000000020002L});
    public static final BitSet FOLLOW_POW_in_pow_expr252 = new BitSet(new long[]{0x0000000000001610L});
    public static final BitSet FOLLOW_pow_expr_in_pow_expr255 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_primary_expr_in_unary_expr276 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_IDENTIFIER_in_unary_expr281 = new BitSet(new long[]{0x0000000000001000L});
    public static final BitSet FOLLOW_LPAR_in_unary_expr283 = new BitSet(new long[]{0x0000000000003610L});
    public static final BitSet FOLLOW_add_expr_in_unary_expr285 = new BitSet(new long[]{0x0000000000040000L});
    public static final BitSet FOLLOW_RPAR_in_unary_expr287 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_DECIMAL_LITERAL_in_primary_expr308 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_FLOATING_POINT_LITERAL_in_primary_expr313 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_IDENTIFIER_in_primary_expr318 = new BitSet(new long[]{0x0000000000000002L});
    public static final BitSet FOLLOW_LPAR_in_primary_expr323 = new BitSet(new long[]{0x0000000000003610L});
    public static final BitSet FOLLOW_add_expr_in_primary_expr325 = new BitSet(new long[]{0x0000000000040000L});
    public static final BitSet FOLLOW_RPAR_in_primary_expr327 = new BitSet(new long[]{0x0000000000000002L});

}