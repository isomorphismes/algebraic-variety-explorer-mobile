package org.algebraicvarietyexplorer.ui;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;

public final class AlgebraicSurfaceView extends View {
    public interface InteractionListener {
        void onViewChanged(double yaw, double pitch, double zoom, boolean gestureFinished);
    }

    private static final long INTERACTIVE_RENDER_INTERVAL_MS = 70L;

    private final Paint imagePaint;
    private final ScaleGestureDetector scaleDetector;

    private Bitmap bitmap;
    private InteractionListener interactionListener;
    private double yaw = 0.55;
    private double pitch = -0.35;
    private double zoom = 1.0;
    private float previousX;
    private float previousY;
    private long lastInteractiveRenderAt;

    public AlgebraicSurfaceView(Context context, AttributeSet attributes) {
        super(context, attributes);
        imagePaint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.FILTER_BITMAP_FLAG);
        scaleDetector = new ScaleGestureDetector(context, new ScaleListener());
        setClickable(true);
    }

    public void setInteractionListener(InteractionListener listener) {
        interactionListener = listener;
    }

    public void setRenderedBitmap(Bitmap renderedBitmap) {
        bitmap = renderedBitmap;
        invalidate();
    }

    public Bitmap getRenderedBitmap() {
        return bitmap;
    }

    public double getYaw() {
        return yaw;
    }

    public double getPitch() {
        return pitch;
    }

    public double getZoom() {
        return zoom;
    }

    public void resetView() {
        yaw = 0.55;
        pitch = -0.35;
        zoom = 1.0;
        notifyViewChanged(true);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        canvas.drawColor(0xFF13161B);
        if (bitmap == null) {
            return;
        }

        RectF destination = centeredFit(
                getWidth(), getHeight(), bitmap.getWidth(), bitmap.getHeight());
        canvas.drawBitmap(bitmap, null, destination, imagePaint);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        scaleDetector.onTouchEvent(event);

        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                previousX = event.getX();
                previousY = event.getY();
                return true;

            case MotionEvent.ACTION_MOVE:
                if (event.getPointerCount() == 1 && !scaleDetector.isInProgress()) {
                    rotateFromDrag(event.getX(), event.getY());
                }
                previousX = event.getX();
                previousY = event.getY();
                return true;

            case MotionEvent.ACTION_UP:
                performClick();
                notifyViewChanged(true);
                return true;

            case MotionEvent.ACTION_CANCEL:
                notifyViewChanged(true);
                return true;

            default:
                return true;
        }
    }

    @Override
    public boolean performClick() {
        super.performClick();
        return true;
    }

    private void rotateFromDrag(float x, float y) {
        double safeWidth = Math.max(1.0, getWidth());
        double safeHeight = Math.max(1.0, getHeight());
        yaw += (x - previousX) * Math.PI * 1.5 / safeWidth;
        pitch += (y - previousY) * Math.PI * 1.5 / safeHeight;
        pitch = clamp(pitch, -1.45, 1.45);
        notifyViewChanged(false);
    }

    private void notifyViewChanged(boolean gestureFinished) {
        if (interactionListener == null) {
            return;
        }

        long now = android.os.SystemClock.uptimeMillis();
        if (!gestureFinished
                && now - lastInteractiveRenderAt < INTERACTIVE_RENDER_INTERVAL_MS) {
            return;
        }
        lastInteractiveRenderAt = now;
        interactionListener.onViewChanged(yaw, pitch, zoom, gestureFinished);
    }

    private static RectF centeredFit(
            int viewWidth,
            int viewHeight,
            int imageWidth,
            int imageHeight) {
        float scale = Math.min(
                (float) viewWidth / imageWidth,
                (float) viewHeight / imageHeight);
        float width = imageWidth * scale;
        float height = imageHeight * scale;
        float left = (viewWidth - width) / 2.0f;
        float top = (viewHeight - height) / 2.0f;
        return new RectF(left, top, left + width, top + height);
    }

    private static double clamp(double value, double minimum, double maximum) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    private final class ScaleListener
            extends ScaleGestureDetector.SimpleOnScaleGestureListener {
        @Override
        public boolean onScale(ScaleGestureDetector detector) {
            zoom *= detector.getScaleFactor();
            zoom = clamp(zoom, 0.45, 4.0);
            notifyViewChanged(false);
            return true;
        }

        @Override
        public void onScaleEnd(ScaleGestureDetector detector) {
            notifyViewChanged(true);
        }
    }
}
