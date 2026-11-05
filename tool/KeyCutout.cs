// Détourage sur fond uni (incrustation) : alpha selon la distance de couleur au fond, échantillonné
// dans les coins ; bords décontaminés ; on ne garde que la plus grande forme ; recadrage serré.
// Écrit en C# 5 pour Add-Type de Windows PowerShell 5.1.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class KeyCutout
{
    public static string Run(string src, string dst, int targetWidth, double near, double far)
    {
        Bitmap input = new Bitmap(src);
        int w = input.Width, h = input.Height;
        Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp)) { g.DrawImage(input, 0, 0, w, h); }
        input.Dispose();

        BitmapData data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int stride = data.Stride;
        byte[] px = new byte[stride * h];
        Marshal.Copy(data.Scan0, px, 0, px.Length);

        // Couleur du fond : moyenne de quatre carrés dans les coins.
        double br = 0, bg = 0, bb = 0; int n = 0;
        int s = Math.Max(8, w / 60);
        int[,] corners = new int[,] { { 0, 0 }, { w - s, 0 }, { 0, h - s }, { w - s, h - s } };
        for (int c = 0; c < 4; c++)
            for (int y = corners[c, 1]; y < corners[c, 1] + s; y++)
                for (int x = corners[c, 0]; x < corners[c, 0] + s; x++)
                {
                    int i = y * stride + x * 4;
                    bb += px[i]; bg += px[i + 1]; br += px[i + 2]; n++;
                }
        br /= n; bg /= n; bb /= n;

        double[] alpha = new double[w * h];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int i = y * stride + x * 4;
                double dr = px[i + 2] - br, dg = px[i + 1] - bg, db = px[i] - bb;
                double d = Math.Sqrt(dr * dr + dg * dg + db * db);
                double a = (d - near) / (far - near);
                if (a < 0) a = 0; if (a > 1) a = 1;
                a = a * a * (3 - 2 * a);
                alpha[y * w + x] = a;
            }

        // Plus grande forme (alpha > 0.5), pour retirer le bruit isolé.
        int[] label = new int[w * h];
        int best = 0, bestSize = 0, current = 0;
        Stack<int> stack = new Stack<int>();
        for (int start = 0; start < w * h; start++)
        {
            if (label[start] != 0 || alpha[start] < 0.5) continue;
            current++;
            int size = 0;
            stack.Push(start); label[start] = current;
            while (stack.Count > 0)
            {
                int p = stack.Pop(); size++;
                int px0 = p % w, py0 = p / w;
                for (int k = 0; k < 4; k++)
                {
                    int nx = px0 + (k == 0 ? 1 : k == 1 ? -1 : 0), ny = py0 + (k == 2 ? 1 : k == 3 ? -1 : 0);
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    int q = ny * w + nx;
                    if (label[q] != 0 || alpha[q] < 0.5) continue;
                    label[q] = current; stack.Push(q);
                }
            }
            if (size > bestSize) { bestSize = size; best = current; }
        }
        // Garde aussi la frange douce (alpha < 0.5) autour de la forme principale.
        bool[] keep = new bool[w * h];
        for (int p = 0; p < w * h; p++) keep[p] = label[p] == best;
        for (int pass = 0; pass < 6; pass++)
        {
            bool[] next = (bool[])keep.Clone();
            for (int y = 1; y < h - 1; y++)
                for (int x = 1; x < w - 1; x++)
                {
                    int p = y * w + x;
                    if (keep[p] || alpha[p] <= 0) continue;
                    if (keep[p - 1] || keep[p + 1] || keep[p - w] || keep[p + w]) next[p] = true;
                }
            keep = next;
        }

        int minX = w, minY = h, maxX = 0, maxY = 0;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int p = y * w + x, i = y * stride + x * 4;
                double a = keep[p] ? alpha[p] : 0;
                if (a > 0 && a < 1)
                {
                    // Décontamination : on retire la part de fond mélangée au bord.
                    px[i + 2] = Clamp((px[i + 2] - (1 - a) * br) / a);
                    px[i + 1] = Clamp((px[i + 1] - (1 - a) * bg) / a);
                    px[i] = Clamp((px[i] - (1 - a) * bb) / a);
                }
                px[i + 3] = (byte)Math.Round(a * 255);
                if (a > 0.02) { if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y; }
            }
        Marshal.Copy(px, 0, data.Scan0, px.Length);
        bmp.UnlockBits(data);

        int pad = Math.Max(4, w / 100);
        minX = Math.Max(0, minX - pad); minY = Math.Max(0, minY - pad);
        maxX = Math.Min(w - 1, maxX + pad); maxY = Math.Min(h - 1, maxY + pad);
        int cw = maxX - minX + 1, ch = maxY - minY + 1;
        int ow = Math.Min(targetWidth, cw), oh = (int)Math.Round((double)ch * ow / cw);
        Bitmap output = new Bitmap(ow, oh, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(output))
        {
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingMode = CompositingMode.SourceCopy;
            g.DrawImage(bmp, new Rectangle(0, 0, ow, oh), new Rectangle(minX, minY, cw, ch), GraphicsUnit.Pixel);
        }
        output.Save(dst, ImageFormat.Png);
        output.Dispose(); bmp.Dispose();
        return "{\"w\":" + ow + ",\"h\":" + oh + ",\"crop\":[" + minX + "," + minY + "," + cw + "," + ch + "],\"src\":[" + w + "," + h + "]}";
    }

    static byte Clamp(double v)
    {
        if (v < 0) return 0;
        if (v > 255) return 255;
        return (byte)Math.Round(v);
    }
}
