package org.algebraicvarietyexplorer.render;

import android.os.Handler;
import android.os.Looper;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

public final class SurfaceRenderController {
    public interface Listener {
        void onRenderingStarted(int width, int height);
        void onRenderingCompleted(RenderResult result);
        void onRenderingFailed(String message);
    }

    private final RendererEngine engine;
    private final ExecutorService renderQueue;
    private final Handler mainThread;
    private final AtomicInteger latestGeneration;
    private final Listener listener;

    public SurfaceRenderController(Listener listener) {
        this.listener = listener;
        this.engine = new RendererEngine();
        this.renderQueue = Executors.newSingleThreadExecutor();
        this.mainThread = new Handler(Looper.getMainLooper());
        this.latestGeneration = new AtomicInteger();
    }

    public void request(
            String formula,
            double yaw,
            double pitch,
            double zoom,
            int viewWidth,
            int viewHeight,
            RenderQuality quality) {
        if (formula == null || formula.trim().isEmpty() || viewWidth <= 0 || viewHeight <= 0) {
            return;
        }

        int generation = latestGeneration.incrementAndGet();
        RenderRequest request = sizeRequest(
                formula.trim(), yaw, pitch, zoom, viewWidth, viewHeight, quality);

        engine.interrupt();
        listener.onRenderingStarted(request.width, request.height);
        renderQueue.submit(() -> render(generation, request));
    }

    public void close() {
        latestGeneration.incrementAndGet();
        engine.close();
        renderQueue.shutdownNow();
    }

    private void render(int generation, RenderRequest request) {
        try {
            RenderResult result = engine.render(request);
            if (generation == latestGeneration.get()) {
                mainThread.post(() -> listener.onRenderingCompleted(result));
            }
        } catch (Throwable error) {
            if (generation == latestGeneration.get()) {
                String message = usefulMessage(error);
                mainThread.post(() -> listener.onRenderingFailed(message));
            }
        }
    }

    private static RenderRequest sizeRequest(
            String formula,
            double yaw,
            double pitch,
            double zoom,
            int viewWidth,
            int viewHeight,
            RenderQuality quality) {
        double scale = (double) quality.maximumDimension() / Math.max(viewWidth, viewHeight);
        scale = Math.min(1.0, scale);

        int width = Math.max(32, (int) Math.round(viewWidth * scale));
        int height = Math.max(32, (int) Math.round(viewHeight * scale));
        return new RenderRequest(formula, yaw, pitch, zoom, width, height, quality);
    }

    private static String usefulMessage(Throwable error) {
        Throwable current = error;
        while (current.getCause() != null) {
            current = current.getCause();
        }
        String message = current.getMessage();
        if (message == null || message.trim().isEmpty()) {
            return current.getClass().getSimpleName();
        }
        return message;
    }
}
