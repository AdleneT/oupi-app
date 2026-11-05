// Détourage par différence avec un décor vide : on compare une image à la même image sans ses
// personnages (le « décor vide », généré par retouche) ; ce qui change, ce sont les personnages.
// L'alpha final vient d'un détourage automatique (qui garde parfois une partie du décor), multiplié
// par ce masque de différence, fermé et rempli pour couvrir l'intérieur des personnages.
// Une image de zone (blanc = décor à surveiller, gris = surveillé sans ouverture, pour un fil fin ;
// noir = détourage fiable) limite ce contrôle à l'endroit
// où le détourage a gardé du décor ; ailleurs, l'alpha du détourage reste tel quel.
// Sortie : un PNG de la même taille que l'image, pour rester calé sur le décor vide.
// Écrit en C# 5 pour Add-Type de Windows PowerShell 5.1.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class DiffCutout
{
    static byte[] Read(string path, out int w, out int h, out int stride)
    {
        Bitmap input = new Bitmap(path);
        w = input.Width; h = input.Height;
        Bitmap bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        using (Graphics g = Graphics.FromImage(bmp)) { g.DrawImage(input, 0, 0, w, h); }
        input.Dispose();
        BitmapData data = bmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        stride = data.Stride;
        byte[] px = new byte[stride * h];
        Marshal.Copy(data.Scan0, px, 0, px.Length);
        bmp.UnlockBits(data);
        bmp.Dispose();
        return px;
    }

    // Vrai si au moins un pixel du carré (2r+1)² est allumé (dilatation), ou s'ils le sont tous (érosion).
    static bool[] Morph(bool[] m, int w, int h, int r, bool dilate)
    {
        int[] sat = new int[(w + 1) * (h + 1)];
        for (int y = 0; y < h; y++)
        {
            int row = 0;
            for (int x = 0; x < w; x++)
            {
                if (m[y * w + x]) row++;
                sat[(y + 1) * (w + 1) + x + 1] = sat[y * (w + 1) + x + 1] + row;
            }
        }
        bool[] o = new bool[w * h];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int x0 = Math.Max(0, x - r), y0 = Math.Max(0, y - r), x1 = Math.Min(w, x + r + 1), y1 = Math.Min(h, y + r + 1);
                int s = sat[y1 * (w + 1) + x1] - sat[y0 * (w + 1) + x1] - sat[y1 * (w + 1) + x0] + sat[y0 * (w + 1) + x0];
                o[y * w + x] = dilate ? s > 0 : s == (x1 - x0) * (y1 - y0);
            }
        return o;
    }

    public static string Run(string image, string plate, string cut, string zone, string dst, int threshold, int close, int minArea, int open)
    {
        int w, h, s, w2, h2, s2, w3, h3, s3;
        byte[] a = Read(image, out w, out h, out s);
        byte[] b = Read(plate, out w2, out h2, out s2);
        byte[] c = Read(cut, out w3, out h3, out s3);
        if (w2 != w || h2 != h || w3 != w || h3 != h) throw new Exception("tailles différentes");
        int w4, h4, s4;
        byte[] z = Read(zone, out w4, out h4, out s4);
        if (w4 != w || h4 != h) throw new Exception("zone : taille différente");

        // 1. Pixels qui changent entre l'image et le décor vide, parmi ceux que le détourage a gardés.
        bool[] m = new bool[w * h];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int i = y * s + x * 4;
                int d = Math.Max(Math.Abs(a[i] - b[i]), Math.Max(Math.Abs(a[i + 1] - b[i + 1]), Math.Abs(a[i + 2] - b[i + 2])));
                m[y * w + x] = d > threshold && c[i + 3] > 64;
            }

        // 2. Fermeture : relie les contours des personnages sans trop déborder.
        m = Morph(Morph(m, w, h, close, true), w, h, close, false);

        // 3. On remplit l'intérieur : tout ce qui n'est pas joignable depuis les bords devient personnage.
        bool[] outside = new bool[w * h];
        Queue<int> q = new Queue<int>();
        for (int x = 0; x < w; x++) { q.Enqueue(x); q.Enqueue((h - 1) * w + x); }
        for (int y = 0; y < h; y++) { q.Enqueue(y * w); q.Enqueue(y * w + w - 1); }
        while (q.Count > 0)
        {
            int p = q.Dequeue();
            if (outside[p] || m[p]) continue;
            outside[p] = true;
            int px = p % w, py = p / w;
            if (px > 0) q.Enqueue(p - 1);
            if (px < w - 1) q.Enqueue(p + 1);
            if (py > 0) q.Enqueue(p - w);
            if (py < h - 1) q.Enqueue(p + w);
        }
        for (int p = 0; p < w * h; p++) m[p] = !outside[p];

        // 4. On retire les petites taches isolées (texture du décor légèrement décalée).
        int[] label = new int[w * h];
        int next = 0;
        int kept = 0;
        for (int p0 = 0; p0 < w * h; p0++)
        {
            if (!m[p0] || label[p0] != 0) continue;
            next++;
            List<int> comp = new List<int>();
            q.Enqueue(p0); label[p0] = next;
            while (q.Count > 0)
            {
                int p = q.Dequeue(); comp.Add(p);
                int px = p % w, py = p / w;
                int[] nb = { px > 0 ? p - 1 : -1, px < w - 1 ? p + 1 : -1, py > 0 ? p - w : -1, py < h - 1 ? p + w : -1 };
                foreach (int n in nb) if (n >= 0 && m[n] && label[n] == 0) { label[n] = next; q.Enqueue(n); }
            }
            if (comp.Count < minArea) foreach (int p in comp) m[p] = false; else kept++;
        }

        // 5. Dans la zone surveillée, une ouverture efface les miettes de décor restées accrochées.
        bool[] opened = open > 0 ? Morph(Morph(m, w, h, open, false), w, h, open, true) : m;
        bool[] inner = Morph(opened, w, h, 2, false);
        bool[] innerM = Morph(m, w, h, 2, false);
        Bitmap outBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
        BitmapData od = outBmp.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
        byte[] o = new byte[od.Stride * h];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int i = y * s + x * 4, j = y * od.Stride + x * 4, p = y * w + x;
                int zv = z[y * s4 + x * 4 + 2];
                double k;
                if (zv < 100) k = 1.0;
                else if (zv > 200) k = inner[p] ? 1.0 : (opened[p] ? 0.5 : 0.0);
                else k = innerM[p] ? 1.0 : (m[p] ? 0.5 : 0.0);
                int alpha = (int)Math.Round(c[i + 3] * k);
                o[j] = c[i]; o[j + 1] = c[i + 1]; o[j + 2] = c[i + 2]; o[j + 3] = (byte)alpha;
            }
        Marshal.Copy(o, 0, od.Scan0, o.Length);
        outBmp.UnlockBits(od);
        outBmp.Save(dst, ImageFormat.Png);
        outBmp.Dispose();
        return "{\"components\":" + kept + "}";
    }
}
