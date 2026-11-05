using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

// Prépare un personnage détouré pour l'animation « Live 2D » de l'appli :
// - sépare la pousse (pixels verts du haut) du corps, sur deux calques de même taille ;
// - donne le point de pivot de la tige (bas de la pousse) ;
// - repère les yeux bleus d'Oupi (centre et taille) pour le clignement.
// Les coordonnées sont des fractions de la largeur et de la hauteur de l'image.
public static class SpritePrep
{
    static bool IsLeaf(byte b, byte g, byte r, byte a) { return a > 20 && g > r + 8 && g > b + 25; }
    static bool IsIris(byte b, byte g, byte r, byte a) { return a > 200 && b > r + 45 && b > g + 15 && r < 120; }

    public static string Run(string src, string outBody, string outSprout, bool findEyes)
    {
        using (var bmp = new Bitmap(src))
        {
            int W = bmp.Width, H = bmp.Height;
            var rect = new Rectangle(0, 0, W, H);
            var d = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            var px = new byte[d.Stride * H]; Marshal.Copy(d.Scan0, px, 0, px.Length);
            int stride = d.Stride; bmp.UnlockBits(d);

            var body = (byte[])px.Clone();
            var sprout = new byte[px.Length];
            // 1. Pixels nettement verts : cadre des feuilles et bas de la tige.
            int sproutMaxY = -1, bMinX = W, bMaxX = -1, bMinY = H; long sumX = 0; int nBase = 0;
            int limitY = (int)(H * 0.42);
            for (int y = 0; y < limitY; y++)
                for (int x = 0; x < W; x++)
                {
                    int i = y * stride + x * 4;
                    if (!IsLeaf(px[i], px[i + 1], px[i + 2], px[i + 3])) continue;
                    if (y > sproutMaxY) sproutMaxY = y;
                    if (x < bMinX) bMinX = x; if (x > bMaxX) bMaxX = x; if (y < bMinY) bMinY = y;
                }
            for (int y = Math.Max(0, sproutMaxY - 6); y <= sproutMaxY; y++)
                for (int x = 0; x < W; x++)
                {
                    int i = y * stride + x * 4;
                    if (IsLeaf(px[i], px[i + 1], px[i + 2], px[i + 3])) { sumX += x; nBase++; }
                }
            double pivotX = nBase > 0 ? (double)sumX / nBase / W : 0.5;
            double pivotY = (double)sproutMaxY / H;

            // 2. Calque pousse : tout le vert-jaune (feuilles, nervures, bords adoucis) dans le cadre,
            //    au-dessus de la base de la tige, sauf le pelage orange et le crème des oreilles.
            int pad = 4;
            for (int y = Math.Max(0, bMinY - pad); y <= sproutMaxY; y++)
                for (int x = Math.Max(0, bMinX - pad); x <= Math.Min(W - 1, bMaxX + pad); x++)
                {
                    int i = y * stride + x * 4;
                    byte b = px[i], g = px[i + 1], r = px[i + 2], a = px[i + 3];
                    if (a == 0) continue;
                    bool leafy = g >= r - 12 && g > b + 10;
                    bool faint = a < 90 && !(r > g + 30) && y < sproutMaxY - 10;
                    if (!leafy && !faint) continue;
                    Array.Copy(px, i, sprout, i, 4);
                    body[i + 3] = 0;
                }

            Save(body, W, H, stride, outBody);
            Save(sprout, W, H, stride, outSprout);

            string eyes = "[]";
            if (findEyes)
            {
                // Deux yeux : iris bleus à gauche et à droite du pivot.
                int[] minX = { int.MaxValue, int.MaxValue }, maxX = { -1, -1 }, minY = { int.MaxValue, int.MaxValue }, maxY = { -1, -1 };
                int splitX = (int)(pivotX * W);
                for (int y = (int)(H * 0.2); y < (int)(H * 0.7); y++)
                    for (int x = 0; x < W; x++)
                    {
                        int i = y * stride + x * 4;
                        if (!IsIris(px[i], px[i + 1], px[i + 2], px[i + 3])) continue;
                        int k = x < splitX ? 0 : 1;
                        if (x < minX[k]) minX[k] = x; if (x > maxX[k]) maxX[k] = x;
                        if (y < minY[k]) minY[k] = y; if (y > maxY[k]) maxY[k] = y;
                    }
                var parts = new System.Collections.Generic.List<string>();
                for (int k = 0; k < 2; k++)
                    if (maxX[k] >= 0)
                        parts.Add("{" + string.Format(System.Globalization.CultureInfo.InvariantCulture,
                            "\"x\":{0:F4},\"y\":{1:F4},\"w\":{2:F4},\"h\":{3:F4}",
                            (double)minX[k] / W, (double)minY[k] / H, (double)(maxX[k] - minX[k] + 1) / W, (double)(maxY[k] - minY[k] + 1) / H) + "}");
                eyes = "[" + string.Join(",", parts) + "]";
            }
            return string.Format(System.Globalization.CultureInfo.InvariantCulture,
                "{{\"size\":[{0},{1}],\"pivot\":[{2:F4},{3:F4}],\"eyes\":{4}}}", W, H, pivotX, pivotY, eyes);
        }
    }

    static void Save(byte[] px, int W, int H, int stride, string path)
    {
        using (var outBmp = new Bitmap(W, H, PixelFormat.Format32bppArgb))
        {
            var d = outBmp.LockBits(new Rectangle(0, 0, W, H), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            Marshal.Copy(px, 0, d.Scan0, Math.Min(px.Length, d.Stride * H));
            outBmp.UnlockBits(d);
            outBmp.Save(path, ImageFormat.Png);
        }
    }
}
