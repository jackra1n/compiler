package ch.hslu.cobau.minij;

import ch.hslu.cobau.minij.ast.AstBuilder;
import ch.hslu.cobau.minij.ast.SemanticAnalyzer;
import ch.hslu.cobau.minij.ast.entity.Unit;
import org.antlr.v4.runtime.*;

import java.io.IOException;

public class MiniJCompiler {
    private static class EnhancedConsoleErrorListener extends ConsoleErrorListener {
        private boolean hasErrors;

        @Override
        public void syntaxError(Recognizer<?, ?> recognizer, Object offendingSymbol, int line, int charPositionInLine, String msg, RecognitionException e) {
            super.syntaxError(recognizer, offendingSymbol, line, charPositionInLine, msg, e);
            hasErrors = true;
        }

        public boolean hasErrors() {
            return hasErrors;
        }
    }

    public static void main(String[] args) throws IOException {    
        // initialize lexer and parser
        CharStream charStream;
        if (args.length > 0) {
            charStream = CharStreams.fromFileName(args[0]);
        } else {
            charStream = CharStreams.fromStream(System.in);
        }
        
        MiniJLexer miniJLexer = new MiniJLexer(charStream);
        CommonTokenStream commonTokenStream = new CommonTokenStream(miniJLexer);
        MiniJParser miniJParser = new MiniJParser(commonTokenStream);
        
        EnhancedConsoleErrorListener errorListener = new EnhancedConsoleErrorListener();
        miniJParser.removeErrorListeners();
        miniJParser.addErrorListener(errorListener);

        // start parsing at outermost level (milestone 2)
        MiniJParser.UnitContext unitContext = miniJParser.unit();
        AstBuilder astBuilder = new AstBuilder();
        astBuilder.visit(unitContext);
        Unit unit = astBuilder.getUnit();

        // semantic check (milestone 3)
        SemanticAnalyzer semanticAnalyzer = new SemanticAnalyzer();
        boolean isValid = semanticAnalyzer.analyze(unit);
        // code generation (milestone 4)

        System.exit((errorListener.hasErrors() || !isValid) ? 1 : 0);
    }
}
