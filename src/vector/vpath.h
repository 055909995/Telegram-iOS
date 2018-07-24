#ifndef VPATH_H
#define VPATH_H
#include "vpoint.h"
#include "vrect.h"
#include "vmatrix.h"
#include<vector>
#include<vcowptr.h>

V_BEGIN_NAMESPACE

struct VPathData;
class VPath
{
public:
    enum class Direction {
        CCW,
        CW
    };

    enum class Element : uchar {
        MoveTo,
        LineTo,
        CubicTo,
        Close
    };
    bool isEmpty()const;
    void moveTo(const VPointF &p);
    void moveTo(float x, float y);
    void lineTo(const VPointF &p);
    void lineTo(float x, float y);
    void cubicTo(const VPointF &c1, const VPointF &c2, const VPointF &e);
    void cubicTo(float c1x, float c1y, float c2x, float c2y, float ex, float ey);
    void arcTo(const VRectF &rect, float startAngle, float sweepLength, bool forceMoveTo);
    void close();
    void reset();
    void reserve(int num_elm);
    int segments() const;
    void addCircle(float cx, float cy, float radius, VPath::Direction dir = Direction::CW);
    void addOval(const VRectF &rect, VPath::Direction dir = Direction::CW);
    void addRoundRect(const VRectF &rect, float rx, float ry, VPath::Direction dir = Direction::CW);
    void addRect(const VRectF &rect, VPath::Direction dir = Direction::CW);
    void addPolystar(float points, float innerRadius, float outerRadius,
                     float innerRoundness, float outerRoundness,
                     float startAngle, float cx, float cy, VPath::Direction dir = Direction::CW);
    void addPolygon(float points, float radius, float roundness,
                    float startAngle, float cx, float cy, VPath::Direction dir = Direction::CW);
    void transform(const VMatrix &m);
    const std::vector<VPath::Element> &elements() const;
    const std::vector<VPointF> &points() const;
private:
    struct VPathData {
        VPathData();
        VPathData(const VPathData &o);
        bool isEmpty() const { return m_elements.empty();}
        void moveTo(const VPointF &pt);
        void lineTo(const VPointF &pt);
        void cubicTo(const VPointF &c1, const VPointF &c2, const VPointF &e);
        void close();
        void reset();
        void reserve(int num_elm);
        void checkNewSegment();
        int  segments() const;
        void transform(const VMatrix &m);
        void addRoundRect(const VRectF &, float, float, VPath::Direction);
        void addRect(const VRectF &, VPath::Direction);
        void arcTo(const VRectF&, float, float, bool);
        void addCircle(float, float, float, VPath::Direction);
        void addOval(const VRectF &, VPath::Direction);
        void addPolystar(float points, float innerRadius, float outerRadius,
                         float innerRoundness, float outerRoundness,
                         float startAngle, float cx, float cy, VPath::Direction dir = Direction::CW);
        void addPolygon(float points, float radius, float roundness,
                        float startAngle, float cx, float cy, VPath::Direction dir = Direction::CW);
        const std::vector<VPath::Element> &elements() const { return m_elements;}
        const std::vector<VPointF> &points() const {return m_points;}
        std::vector<VPointF>         m_points;
        std::vector<VPath::Element>  m_elements;
        int                          m_segments;
        VPointF                      mStartPoint;
        bool                         mNewSegment;
    };

    vcow_ptr<VPathData> d;
};

inline bool VPath::isEmpty()const
{
    return d->isEmpty();
}

inline void VPath::moveTo(const VPointF &p)
{
    d.write().moveTo(p);
}

inline void VPath::lineTo(const VPointF &p)
{
    d.write().lineTo(p);
}

inline void VPath::close()
{
    d.write().close();
}

inline void VPath::reset()
{
    d.write().reset();
}

inline void VPath::reserve(int num_elm)
{
    d.write().reserve(num_elm);
}

inline int VPath::segments() const
{
    return d->segments();
}

inline void VPath::cubicTo(const VPointF &c1, const VPointF &c2, const VPointF &e)
{
    d.write().cubicTo(c1, c2, e);
}

inline void VPath::lineTo(float x, float y)
{
    lineTo(VPointF(x,y));
}

inline void VPath::moveTo(float x, float y)
{
    moveTo(VPointF(x,y));
}

inline void VPath::cubicTo(float c1x, float c1y, float c2x, float c2y, float ex, float ey)
{
    cubicTo(VPointF(c1x, c1y), VPointF(c2x, c2y), VPointF(ex, ey));
}

inline void VPath::transform(const VMatrix &m)
{
    d.write().transform(m);
}

inline void VPath::arcTo(const VRectF &rect, float startAngle, float sweepLength, bool forceMoveTo)
{
    d.write().arcTo(rect, startAngle, sweepLength, forceMoveTo);
}

inline void VPath::addRect(const VRectF &rect, VPath::Direction dir)
{
    d.write().addRect(rect, dir);
}

inline void VPath::addRoundRect(const VRectF &rect, float rx, float ry, VPath::Direction dir)
{
   d.write().addRoundRect(rect, rx, ry, dir);
}

inline void VPath::addCircle(float cx, float cy, float radius, VPath::Direction dir)
{
    d.write().addCircle(cx, cy, radius, dir);
}

inline void VPath::addOval(const VRectF &rect, VPath::Direction dir)
{
    d.write().addOval(rect, dir);
}

inline void VPath::addPolystar(float points, float innerRadius, float outerRadius,
                               float innerRoundness, float outerRoundness,
                               float startAngle, float cx, float cy, VPath::Direction dir)
{
    d.write().addPolystar(points, innerRadius, outerRadius,
                          innerRoundness, outerRoundness,
                          startAngle, cx, cy, dir);
}

inline void VPath::addPolygon(float points, float radius, float roundness,
                              float startAngle, float cx, float cy, VPath::Direction dir)
{
    d.write().addPolygon(points, radius, roundness,
                         startAngle, cx, cy, dir);
}

inline const std::vector<VPath::Element> &VPath::elements() const
{
    return d->elements();
}

inline const std::vector<VPointF> &VPath::points() const
{
    return d->points();
}

V_END_NAMESPACE

#endif // VPATH_H
