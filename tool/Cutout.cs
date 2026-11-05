using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

// Détourage d'une planche à fond crème uni :
// 1. fond = remplissage depuis les bords des pixels proches du crème ;
// 2. ombre au sol = pixels gris plus sombres que le fond, seulement sous la ligne des pieds ;
// 3. on ne garde que la plus grande forme de la bande (pas de morceaux des voisins) ;
// 4. bord adouci selon l'écart de couleur au fond, couleur décontaminée du crème.
public static class Cutout
{
    public static void Run(string src, string dst, int x0, int x1, int targetHeight, double shadowFrac = 0.755, double legFrac = 0.72)
    {
        using (var full = new Bitmap(src))
        {
            int W = full.Width, H = full.Height;
            var rect = new Rectangle(0, 0, W, H);
            using (var bmp = full.Clone(rect, PixelFormat.Format32bppArgb))
            {
                var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
                int stride = data.Stride;
                var px = new byte[stride * H];
                Marshal.Copy(data.Scan0, px, 0, px.Length);

                double br = 0, bg = 0, bb = 0; int n = 0;
                foreach (var c in new[] { new[] { 5, 5 }, new[] { W - 6, 5 }, new[] { 5, H - 6 }, new[] { W - 6, H - 6 } })
                    for (int dy = -3; dy <= 3; dy++) for (int dx = -3; dx <= 3; dx++)
                    {
                        int i = (c[1] + dy) * stride + (c[0] + dx) * 4;
                        bb += px[i]; bg += px[i + 1]; br += px[i + 2]; n++;
                    }
                br /= n; bg /= n; bb /= n;
                double bgLum = 0.299 * br + 0.587 * bg + 0.114 * bb;
                int shadowY = (int)(H * shadowFrac);

                var dist = new double[W * H];
                var lum = new double[W * H];
                for (int y = 0; y < H; y++)
                    for (int x = 0; x < W; x++)
                    {
                        int i = y * stride + x * 4;
                        double b = px[i], g = px[i + 1], r = px[i + 2];
                        dist[y * W + x] = Math.Sqrt((r - br) * (r - br) + (g - bg) * (g - bg) + (b - bb) * (b - bb));
                        lum[y * W + x] = 0.299 * r + 0.587 * g + 0.114 * b;
                    }

                // 0 = personnage, 1 = fond, 2 = ombre
                var cls = new byte[W * H];
                var seen = new bool[W * H];
                var q = new Queue<int>();
                for (int x = 0; x < W; x++) { q.Enqueue(x); q.Enqueue((H - 1) * W + x); }
                for (int y = 0; y < H; y++) { q.Enqueue(y * W); q.Enqueue(y * W + W - 1); }
                while (q.Count > 0)
                {
                    int p = q.Dequeue();
                    if (seen[p]) continue;
                    seen[p] = true;
                    int x = p % W, y = p / W, i = y * stride + x * 4;
                    int k = 0;
                    if (dist[p] < 10) k = 1;
                    else if (y >= shadowY)
                    {
                        double r = px[i + 2], g = px[i + 1], b = px[i];
                        double lumDiff = bgLum - lum[p];
                        double warmth = (r - b) - (br - bb);
                        double chroma = Math.Max(r, Math.Max(g, b)) - Math.Min(r, Math.Min(g, b));
                        // Sous la ligne des pieds : neutre et plus sombre = ombre, neutre et clair = sol à effacer.
                        if ((warmth < 14 && chroma < 40 && lumDiff < 75) || (chroma < 28 && dist[p] < 34)) k = lumDiff > 4 ? 2 : 1;
                    }
                    if (k == 0) continue;
                    cls[p] = (byte)k;
                    if (x > 0) q.Enqueue(p - 1);
                    if (x < W - 1) q.Enqueue(p + 1);
                    if (y > 0) q.Enqueue(p - W);
                    if (y < H - 1) q.Enqueue(p + W);
                }

                // Entre les jambes, le fond est encerclé par l'ombre chaude : on l'efface même non relié aux bords.
                int legY = (int)(H * legFrac);
                for (int y = legY; y < H; y++)
                    for (int x = 0; x < W; x++)
                        if (cls[y * W + x] == 0 && dist[y * W + x] < 9) cls[y * W + x] = 1;

                // Plus grande forme (8-connexe) de pixels personnage dans la bande.
                int xEnd = Math.Min(x1, W);
                var comp = new int[W * H];
                int best = 0, bestSize = 0, label = 0;
                for (int y = 0; y < H; y++)
                    for (int x = x0; x < xEnd; x++)
                    {
                        int p = y * W + x;
                        if (cls[p] != 0 || comp[p] != 0) continue;
                        label++;
                        int size = 0;
                        q.Enqueue(p); comp[p] = label;
                        while (q.Count > 0)
                        {
                            int c = q.Dequeue(); size++;
                            int cx = c % W, cy = c / W;
                            for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++)
                            {
                                int nx = cx + dx, ny = cy + dy;
                                if (nx < x0 || nx >= xEnd || ny < 0 || ny >= H) continue;
                                int np = ny * W + nx;
                                if (cls[np] == 0 && comp[np] == 0) { comp[np] = label; q.Enqueue(np); }
                            }
                        }
                        if (size > bestSize) { bestSize = size; best = label; }
                    }
                int minX = int.MaxValue, minY = int.MaxValue, maxX = -1, maxY = -1;
                for (int y = 0; y < H; y++)
                    for (int x = x0; x < xEnd; x++)
                        if (comp[y * W + x] == best)
                        {
                            if (x < minX) minX = x; if (x > maxX) maxX = x; if (y < minY) minY = y; if (y > maxY) maxY = y;
                        }

                // Distance au fond (en pixels, jusqu'à 3) pour adoucir le bord.
                var edge = new byte[W * H];
                var eq = new Queue<int>();
                for (int p = 0; p < W * H; p++) if (cls[p] != 0) { eq.Enqueue(p); }
                var ed = new int[W * H];
                for (int p = 0; p < W * H; p++) ed[p] = cls[p] != 0 ? 0 : 99;
                while (eq.Count > 0)
                {
                    int c = eq.Dequeue(); int cx = c % W, cy = c / W;
                    if (ed[c] >= 3) continue;
                    int[] nbs = { c - 1, c + 1, c - W, c + W };
                    for (int t = 0; t < 4; t++)
                    {
                        int np = nbs[t];
                        if (np < 0 || np >= W * H) continue;
                        if ((t == 0 && cx == 0) || (t == 1 && cx == W - 1)) continue;
                        if (ed[np] > ed[c] + 1) { ed[np] = ed[c] + 1; eq.Enqueue(np); }
                    }
                }

                int sMinX = minX - 50, sMaxX = maxX + 50;
                for (int y = 0; y < H; y++)
                    for (int x = 0; x < W; x++)
                    {
                        int p = y * W + x, i = y * stride + x * 4;
                        bool keepShadow = cls[p] == 2 && x >= sMinX && x <= sMaxX;
                        if (keepShadow)
                        {
                            double a = Math.Min(140, Math.Max(0, (bgLum - lum[p]) * 3.0));
                            px[i] = 30; px[i + 1] = 30; px[i + 2] = 60; px[i + 3] = (byte)a;
                            continue;
                        }
                        if (cls[p] != 0 || comp[p] != best) { px[i + 3] = 0; continue; }
                        int d = ed[p];
                        if (d <= 3)
                        {
                            double aColor = Math.Max(0, Math.Min(1, (dist[p] - 6) / 30.0));
                            double a = d == 1 ? aColor : d == 2 ? Math.Max(aColor, 0.55) : Math.Max(aColor, 0.85);
                            if (a < 0.04) { px[i + 3] = 0; continue; }
                            for (int ch = 0; ch < 3; ch++)
                            {
                                double bgc = ch == 0 ? bb : ch == 1 ? bg : br;
                                double v = (px[i + ch] - (1 - a) * bgc) / a;
                                px[i + ch] = (byte)Math.Max(0, Math.Min(255, v));
                            }
                            px[i + 3] = (byte)(a * 255);
                        }
                    }
                // Boîte : la forme gardée plus son ombre.
                for (int y = shadowY; y < H; y++)
                    for (int x = Math.Max(0, sMinX); x <= Math.Min(W - 1, sMaxX); x++)
                        if (cls[y * W + x] == 2 && px[y * stride + x * 4 + 3] > 14) { if (y > maxY) maxY = y; }

                // Fondu en transparence des 6 % du bas : la plaque de sol disparaît, l'appli dessine sa propre ombre.
                int fadeH = (int)((maxY - minY) * 0.06);
                for (int y = maxY - fadeH; y <= maxY; y++)
                {
                    double f = Math.Max(0, Math.Min(1, (double)(maxY - y) / fadeH));
                    for (int x = 0; x < W; x++) { int i = y * stride + x * 4; px[i + 3] = (byte)(px[i + 3] * f); }
                }
                for (int y = maxY + 1; y < H; y++)
                    for (int x = 0; x < W; x++) px[y * stride + x * 4 + 3] = 0;
                Marshal.Copy(px, 0, data.Scan0, px.Length);
                bmp.UnlockBits(data);
                int pad = 6;
                minX = Math.Max(0, minX - pad); minY = Math.Max(0, minY - pad);
                maxX = Math.Min(W - 1, maxX + pad); maxY = Math.Min(H - 1, maxY + pad);
                var crop = new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
                double scale = Math.Min(1.0, (double)targetHeight / crop.Height);
                int tw = (int)Math.Round(crop.Width * scale), th = (int)Math.Round(crop.Height * scale);
                using (var outBmp = new Bitmap(tw, th, PixelFormat.Format32bppArgb))
                using (var g2 = Graphics.FromImage(outBmp))
                {
                    g2.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                    g2.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g2.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                    using (var attrs = new ImageAttributes())
                    {
                        attrs.SetWrapMode(System.Drawing.Drawing2D.WrapMode.TileFlipXY);
                        g2.DrawImage(bmp, new Rectangle(0, 0, tw, th), crop.X, crop.Y, crop.Width, crop.Height, GraphicsUnit.Pixel, attrs);
                    }
                    outBmp.Save(dst, ImageFormat.Png);
                }
                Console.WriteLine(string.Format("{0}: crop {1} -> {2}x{3}", System.IO.Path.GetFileName(dst), crop, tw, th));
            }
        }
    }
}
