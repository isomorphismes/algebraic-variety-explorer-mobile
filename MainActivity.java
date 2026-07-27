package org.algebraicvarietyexplorer;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.algebraicvarietyexplorer.render.RenderQuality;
import org.algebraicvarietyexplorer.render.RenderResult;
import org.algebraicvarietyexplorer.render.SurfaceRenderController;
import org.algebraicvarietyexplorer.samples.SurfaceExample;
import org.algebraicvarietyexplorer.samples.SurfaceExamples;
import org.algebraicvarietyexplorer.storage.PngExporter;
import org.algebraicvarietyexplorer.ui.AlgebraicSurfaceView;

public final class MainActivity extends Activity {
    private static final int CREATE_PNG_REQUEST = 1;
    private static final String INITIAL_FORMULA = "x^2+y^2+z^2-0.64";

    private AlgebraicSurfaceView surfaceView;
    private EditText formulaInput;
    private TextView status;
    private SurfaceRenderController renderController;
    private ExecutorService fileQueue;
    private Bitmap pendingBitmapToSave;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            setContentView(R.layout.activity_main);
            bindViews();
            createControllers();
            configureSurfaceInteraction();
            configureFormulaInput();
            configureButtons();
            renderInitialSurface();
        } catch (Throwable error) {
            showStartupError(error);
        }
    }

    @Override
    protected void onDestroy() {
        if (renderController != null) {
            renderController.close();
        }
        if (fileQueue != null) {
            fileQueue.shutdownNow();
        }
        super.onDestroy();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != CREATE_PNG_REQUEST
                || resultCode != RESULT_OK
                || data == null
                || data.getData() == null
                || pendingBitmapToSave == null) {
            return;
        }
        savePng(data.getData(), pendingBitmapToSave);
    }

    private void bindViews() {
        surfaceView = findViewById(R.id.surface_view);
        formulaInput = findViewById(R.id.formula);
        status = findViewById(R.id.status);
    }

    private void createControllers() {
        fileQueue = Executors.newSingleThreadExecutor();
        renderController = new SurfaceRenderController(new RenderListener());
    }

    private void configureSurfaceInteraction() {
        surfaceView.setInteractionListener(
                (yaw, pitch, zoom, gestureFinished) ->
                        renderCurrent(
                                gestureFinished
                                        ? RenderQuality.FINAL
                                        : RenderQuality.INTERACTIVE));
    }

    private void configureFormulaInput() {
        formulaInput.setText(INITIAL_FORMULA);
        formulaInput.setOnEditorActionListener((view, actionId, event) -> {
            boolean enterPressed = event != null
                    && event.getKeyCode() == KeyEvent.KEYCODE_ENTER
                    && event.getAction() == KeyEvent.ACTION_DOWN;
            if (actionId == EditorInfo.IME_ACTION_DONE || enterPressed) {
                hideKeyboard();
                renderCurrent(RenderQuality.FINAL);
                return true;
            }
            return false;
        });
    }

    private void configureButtons() {
        Button render = findViewById(R.id.render);
        Button examples = findViewById(R.id.examples);
        Button save = findViewById(R.id.save);
        Button about = findViewById(R.id.about);

        render.setOnClickListener(view -> {
            hideKeyboard();
            renderCurrent(RenderQuality.FINAL);
        });
        examples.setOnClickListener(view -> showExamples());
        save.setOnClickListener(view -> choosePngDestination());
        about.setOnClickListener(view -> showAbout());
    }

    private void renderInitialSurface() {
        surfaceView.post(() -> renderCurrent(RenderQuality.FINAL));
    }

    private void renderCurrent(RenderQuality quality) {
        renderController.request(
                formulaInput.getText().toString(),
                surfaceView.getYaw(),
                surfaceView.getPitch(),
                surfaceView.getZoom(),
                surfaceView.getWidth(),
                surfaceView.getHeight(),
                quality);
    }

    private void showExamples() {
        List<SurfaceExample> examples = SurfaceExamples.all();
        String[] names = new String[examples.size()];
        for (int index = 0; index < examples.size(); index++) {
            names[index] = examples.get(index).name;
        }

        new AlertDialog.Builder(this)
                .setTitle(R.string.examples)
                .setItems(names, (dialog, selectedIndex) -> {
                    formulaInput.setText(examples.get(selectedIndex).formula);
                    surfaceView.resetView();
                })
                .show();
    }

    private void showAbout() {
        new AlertDialog.Builder(this)
                .setTitle(R.string.about_title)
                .setMessage(R.string.about_body)
                .setPositiveButton(android.R.string.ok, null)
                .show();
    }

    private void choosePngDestination() {
        Bitmap bitmap = surfaceView.getRenderedBitmap();
        if (bitmap == null) {
            Toast.makeText(this, R.string.nothing_to_save, Toast.LENGTH_SHORT).show();
            return;
        }

        pendingBitmapToSave = bitmap;
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("image/png");
        intent.putExtra(Intent.EXTRA_TITLE, "algebraic-variety.png");
        startActivityForResult(intent, CREATE_PNG_REQUEST);
    }

    private void savePng(Uri destination, Bitmap bitmap) {
        fileQueue.submit(() -> {
            try {
                PngExporter.save(getContentResolver(), destination, bitmap);
                runOnUiThread(() ->
                        Toast.makeText(this, R.string.save_success, Toast.LENGTH_SHORT).show());
            } catch (Exception error) {
                runOnUiThread(() ->
                        Toast.makeText(this, R.string.save_failed, Toast.LENGTH_LONG).show());
            }
        });
    }

    private void hideKeyboard() {
        InputMethodManager keyboard = getSystemService(InputMethodManager.class);
        if (keyboard != null) {
            keyboard.hideSoftInputFromWindow(formulaInput.getWindowToken(), 0);
        }
        formulaInput.clearFocus();
    }

    private void showStartupError(Throwable error) {
        ScrollView scroller = new ScrollView(this);
        TextView report = new TextView(this);
        int padding = Math.round(16.0f * getResources().getDisplayMetrics().density);
        report.setPadding(padding, padding, padding, padding);
        report.setTextColor(0xfff3f1ed);
        report.setBackgroundColor(0xff13161b);
        report.setTextIsSelectable(true);
        report.setText(
                "Algebraic Variety Explorer could not start.\n\n"
                        + "This diagnostic replaces Android’s unhelpful crash message. "
                        + "Please send a screenshot of the text below.\n\n"
                        + Log.getStackTraceString(error));
        scroller.addView(
                report,
                new ScrollView.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT));
        setContentView(scroller);
    }

    private final class RenderListener implements SurfaceRenderController.Listener {
        @Override
        public void onRenderingStarted(int width, int height) {
            status.setText(getString(R.string.rendering_status, width, height));
        }

        @Override
        public void onRenderingCompleted(RenderResult result) {
            surfaceView.setRenderedBitmap(result.bitmap);
            status.setText(getString(
                    R.string.complete_status,
                    result.polynomialDegree,
                    result.elapsedMilliseconds));
        }

        @Override
        public void onRenderingFailed(String message) {
            status.setText(getString(R.string.invalid_formula, message));
        }
    }
}
