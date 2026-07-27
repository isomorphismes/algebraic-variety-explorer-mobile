package org.algebraicvarietyexplorer.storage;

import android.content.ContentResolver;
import android.graphics.Bitmap;
import android.net.Uri;

import java.io.IOException;
import java.io.OutputStream;

public final class PngExporter {
    private PngExporter() {
    }

    public static void save(ContentResolver resolver, Uri destination, Bitmap bitmap)
            throws IOException {
        try (OutputStream output = resolver.openOutputStream(destination, "w")) {
            if (output == null || !bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)) {
                throw new IOException("PNG encoder failed");
            }
        }
    }
}
