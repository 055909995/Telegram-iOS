#include "lottieitem.h"
#include <cmath>
#include <algorithm>
#include "vbitmap.h"
#include "vdasher.h"
#include "vpainter.h"
#include "vraster.h"

/* Lottie Layer Rules
 * 1. time stretch is pre calculated and applied to all the properties of the
 * lottilayer model and all its children
 * 2. The frame property could be reversed using,time-reverse layer property in
 * AE. which means (start frame > endFrame) 3.
 */

LOTCompItem::LOTCompItem(LOTModel *model)
    : mRootModel(model), mUpdateViewBox(false), mCurFrameNo(-1)
{
    mCompData = model->mRoot.get();
    mRootLayer = createLayerItem(mCompData->mRootLayer.get());
    mRootLayer->updateStaticProperty();
    mViewSize = mCompData->size();
}

std::unique_ptr<LOTLayerItem>
LOTCompItem::createLayerItem(LOTLayerData *layerData)
{
    switch (layerData->mLayerType) {
    case LayerType::Precomp: {
        return std::make_unique<LOTCompLayerItem>(layerData);
        break;
    }
    case LayerType::Solid: {
        return std::make_unique<LOTSolidLayerItem>(layerData);
        break;
    }
    case LayerType::Shape: {
        return std::make_unique<LOTShapeLayerItem>(layerData);
        break;
    }
    case LayerType::Null: {
        return std::make_unique<LOTNullLayerItem>(layerData);
        break;
    }
    default:
        return nullptr;
        break;
    }
}

void LOTCompItem::resize(const VSize &size)
{
    if (mViewSize == size) return;
    mViewSize = size;
    mUpdateViewBox = true;
}

VSize LOTCompItem::size() const
{
    return mViewSize;
}

bool LOTCompItem::update(int frameNo)
{
    // check if cached frame is same as requested frame.
    if (!mUpdateViewBox && (mCurFrameNo == frameNo)) return false;

    /*
     * if viewbox dosen't scale exactly to the viewport
     * we scale the viewbox keeping AspectRatioPreserved and then align the
     * viewbox to the viewport using AlignCenter rule.
     */
    VSize viewPort = mViewSize;
    VSize viewBox = mCompData->size();

    float sx = float(viewPort.width()) / viewBox.width();
    float sy = float(viewPort.height()) / viewBox.height();
    float scale = fmin(sx, sy);
    float tx = (viewPort.width() - viewBox.width() * scale) * 0.5;
    float ty = (viewPort.height() - viewBox.height() * scale) * 0.5;

    VMatrix m;
    m.scale(scale, scale).translate(tx, ty);
    mRootLayer->update(frameNo, m, 1.0);

    buildRenderList();
    mCurFrameNo = frameNo;
    mUpdateViewBox = false;
    return true;
}

void LOTCompItem::buildRenderList()
{
    mDrawableList.clear();
    mRootLayer->renderList(mDrawableList);

    mRenderList.clear();
    for (auto &i : mDrawableList) {
        LOTDrawable *lotDrawable = static_cast<LOTDrawable *>(i);
        lotDrawable->sync();
        mRenderList.push_back(&lotDrawable->mCNode);
    }
}

const std::vector<LOTNode *> &LOTCompItem::renderList() const
{
    return mRenderList;
}

bool LOTCompItem::render(const LOTBuffer &buffer)
{
    VBitmap bitmap((uchar *)buffer.buffer, buffer.width, buffer.height,
                   buffer.bytesPerLine, VBitmap::Format::ARGB32_Premultiplied,
                   nullptr, nullptr);

    /* schedule all preprocess task for this frame at once.
     */
    for (auto &e : mDrawableList) {
        e->preprocess();
    }

    VPainter painter(&bitmap);
    mRootLayer->render(&painter, {}, {}, nullptr);

    return true;
}

void LOTMaskItem::update(int frameNo, const VMatrix &parentMatrix,
                         float parentAlpha, const DirtyFlag &/*flag*/)
{
    if (mData->mShape.isStatic()) {
        if (mLocalPath.isEmpty()) {
            mData->mShape.value(frameNo).toPath(mLocalPath);
        }
    } else {
        mData->mShape.value(frameNo).toPath(mLocalPath);
    }
    float opacity = mData->opacity(frameNo);
    opacity = opacity * parentAlpha;
    mCombinedAlpha = opacity;

    VPath path = mLocalPath;
    path.transform(parentMatrix);

    mRleTask = VRaster::generateFillInfo(std::move(path), std::move(mRle));
    mRle = VRle();
}

VRle LOTMaskItem::rle()
{
    if (mRleTask.valid()) {
        mRle = mRleTask.get();
        if (!vCompare(mCombinedAlpha, 1.0f))
            mRle *= (mCombinedAlpha * 255);
        if (mData->mInv) mRle.invert();
    }
    return mRle;
}

void LOTLayerItem::render(VPainter *painter, const VRle &inheritMask, const VRle &inheritMatte, LOTLayerItem *matteSource)
{
    VRle matteRle;
    if (matteSource) {
        mDrawableList.clear();
        matteSource->renderList(mDrawableList);
        for (auto &i : mDrawableList) {
            matteRle = matteRle + i->rle();
        }

        if (!inheritMatte.isEmpty())
            matteRle = matteRle & inheritMatte;
    } else {
        matteRle = inheritMatte;
    }
    mDrawableList.clear();
    renderList(mDrawableList);

    VRle mask;
    if (hasMask()) {
        mask = maskRle(painter->clipBoundingRect());
        if (!inheritMask.isEmpty())
            mask = mask & inheritMask;
        // if resulting mask is empty then return.
        if (mask.isEmpty())
            return;
    } else {
        mask = inheritMask;
    }

    for (auto &i : mDrawableList) {
        painter->setBrush(i->mBrush);
        VRle rle = i->rle();
        if (!mask.isEmpty()) rle = rle & mask;

        if (rle.isEmpty()) continue;

        if (!matteRle.isEmpty()) {
            if (mLayerData->mMatteType == MatteType::AlphaInv) {
                rle = rle - matteRle;
            } else {
                rle = rle & matteRle;
            }
        }
        painter->drawRle(VPoint(), rle);
    }
}

VRle LOTLayerItem::maskRle(const VRect &clipRect)
{
    VRle rle;
    for (auto &i : mMasks) {
        switch (i->maskMode()) {
        case LOTMaskData::Mode::Add: {
            rle = rle + i->rle();
            break;
        }
        case LOTMaskData::Mode::Substarct: {
            if (rle.isEmpty() && !clipRect.isEmpty())
                rle = VRle::toRle(clipRect);
            rle = rle - i->rle();
            break;
        }
        case LOTMaskData::Mode::Intersect: {
            rle = rle & i->rle();
            break;
        }
        case LOTMaskData::Mode::Difference: {
            rle = rle ^ i->rle();
            break;
        }
        default:
            break;
        }
    }
    return rle;
}

LOTLayerItem::LOTLayerItem(LOTLayerData *layerData): mLayerData(layerData)
{
    if (mLayerData->mHasMask) {
        for (auto &i : mLayerData->mMasks) {
            mMasks.push_back(std::make_unique<LOTMaskItem>(i.get()));
        }
    }
}

void LOTLayerItem::updateStaticProperty()
{
    if (mParentLayer) mParentLayer->updateStaticProperty();

    mStatic = mLayerData->isStatic();
    mStatic = mParentLayer ? (mStatic & mParentLayer->isStatic()) : mStatic;
    mStatic = mPrecompLayer ? (mStatic & mPrecompLayer->isStatic()) : mStatic;
}

void LOTLayerItem::update(int frameNo, const VMatrix &parentMatrix,
                          float parentAlpha)
{
    mFrameNo = frameNo;
    // 1. check if the layer is part of the current frame
    if (!visible()) return;

    // 2. calculate the parent matrix and alpha
    VMatrix m = matrix(frameNo);
    m *= parentMatrix;
    float alpha = parentAlpha * opacity(frameNo);

    // 6. update the mask
    if (hasMask()) {
        for (auto &i : mMasks) i->update(frameNo, m, alpha, mDirtyFlag);
    }

    // 3. update the dirty flag based on the change
    if (!mCombinedMatrix.fuzzyCompare(m)) {
        mDirtyFlag |= DirtyFlagBit::Matrix;
    }
    if (!vCompare(mCombinedAlpha, alpha)) {
        mDirtyFlag |= DirtyFlagBit::Alpha;
    }
    mCombinedMatrix = m;
    mCombinedAlpha = alpha;

    // 4. if no parent property change and layer is static then nothing to do.
    if ((flag() & DirtyFlagBit::None) && isStatic()) return;

    // 5. update the content of the layer
    updateContent();

    // 6. reset the dirty flag
    mDirtyFlag = DirtyFlagBit::None;
}

float LOTLayerItem::opacity(int frameNo) const
{
    return mLayerData->mTransform->opacity(frameNo);
}

VMatrix LOTLayerItem::matrix(int frameNo) const
{
    if (mParentLayer)
        return mLayerData->mTransform->matrix(frameNo) *
               mParentLayer->matrix(frameNo);
    else
        return mLayerData->mTransform->matrix(frameNo);
}

bool LOTLayerItem::visible() const
{
    if (frameNo() >= mLayerData->inFrame() &&
        frameNo() < mLayerData->outFrame())
        return true;
    else
        return false;
}

LOTCompLayerItem::LOTCompLayerItem(LOTLayerData *layerModel)
    : LOTLayerItem(layerModel)
{
    for (auto &i : mLayerData->mChildren) {
        LOTLayerData *layerModel = dynamic_cast<LOTLayerData *>(i.get());
        if (layerModel) {
            auto layerItem = LOTCompItem::createLayerItem(layerModel);
            if (layerItem) mLayers.push_back(std::move(layerItem));
        }
    }

    // 2. update parent layer
    for (auto &i : mLayers) {
        int id = i->parentId();
        if (id >= 0) {
            auto search = std::find_if(mLayers.begin(), mLayers.end(),
                            [id](const auto& val){ return val->id() == id;});
            if (search != mLayers.end()) i->setParentLayer((*search).get());
        }
        // update the precomp layer if its not the root layer.
        if (!layerModel->root()) i->setPrecompLayer(this);
    }
}

void LOTCompLayerItem::updateStaticProperty()
{
    LOTLayerItem::updateStaticProperty();

    for (auto &i : mLayers) {
        i->updateStaticProperty();
    }
}

void LOTCompLayerItem::render(VPainter *painter, const VRle &inheritMask, const VRle &inheritMatte, LOTLayerItem *matteSource)
{
    VRle matteRle;
    if (matteSource) {
        mDrawableList.clear();
        matteSource->renderList(mDrawableList);
        for (auto &i : mDrawableList) {
            matteRle = matteRle + i->rle();
        }

        if (!inheritMatte.isEmpty())
            matteRle = matteRle & inheritMatte;
    } else {
        matteRle = inheritMatte;
    }

    VRle mask;
    if (hasMask()) {
        mask = maskRle(painter->clipBoundingRect());
        if (!inheritMask.isEmpty())
            mask = mask & inheritMask;
        // if resulting mask is empty then return.
        if (mask.isEmpty())
            return;
    } else {
        mask = inheritMask;
    }

    LOTLayerItem *matteLayer = nullptr;
    for (auto i = mLayers.rbegin(); i != mLayers.rend(); ++i) {
        LOTLayerItem *layer = (*i).get();

        if (!matteLayer && layer->hasMatte()) {
            matteLayer = layer;
            continue;
        }

        if (matteLayer) {
            if (matteLayer->visible() && layer->visible())
                matteLayer->render(painter, mask, matteRle, layer);
            matteLayer = nullptr;
        } else {
            if (layer->visible())
                layer->render(painter, mask, matteRle, nullptr);
        }
    }
}

void LOTCompLayerItem::updateContent()
{
    // update the layer from back to front
    for (auto i = mLayers.rbegin(); i != mLayers.rend(); ++i) {
        (*i)->update(frameNo(), combinedMatrix(), combinedAlpha());
    }
}

void LOTCompLayerItem::renderList(std::vector<VDrawable *> &list)
{
    if (!visible()) return;

    // update the layer from back to front
    for (auto i = mLayers.rbegin(); i != mLayers.rend(); ++i) {
        (*i)->renderList(list);
    }
}

LOTSolidLayerItem::LOTSolidLayerItem(LOTLayerData *layerData)
    : LOTLayerItem(layerData)
{
}

void LOTSolidLayerItem::updateContent()
{
    if (!mRenderNode) {
        mRenderNode = std::make_unique<LOTDrawable>();
        mRenderNode->mType = VDrawable::Type::Fill;
        mRenderNode->mFlag |= VDrawable::DirtyState::All;
    }

    if (flag() & DirtyFlagBit::Matrix) {
        VPath path;
        path.addRect(
            VRectF(0, 0, mLayerData->solidWidth(), mLayerData->solidHeight()));
        path.transform(combinedMatrix());
        mRenderNode->mFlag |= VDrawable::DirtyState::Path;
        mRenderNode->mPath = path;
    }
    if (flag() & DirtyFlagBit::Alpha) {
        LottieColor color = mLayerData->solidColor();
        VBrush      brush(color.toColor(combinedAlpha()));
        mRenderNode->setBrush(brush);
        mRenderNode->mFlag |= VDrawable::DirtyState::Brush;
    }
}

void LOTSolidLayerItem::renderList(std::vector<VDrawable *> &list)
{
    if (!visible()) return;

    list.push_back(mRenderNode.get());
}

LOTNullLayerItem::LOTNullLayerItem(LOTLayerData *layerData)
    : LOTLayerItem(layerData)
{
}
void LOTNullLayerItem::updateContent() {}

LOTShapeLayerItem::LOTShapeLayerItem(LOTLayerData *layerData)
    : LOTLayerItem(layerData)
{
    mRoot = std::make_unique<LOTContentGroupItem>(nullptr);
    mRoot->addChildren(layerData);

    std::vector<LOTPathDataItem *> list;
    mRoot->processPaintItems(list);

    if (layerData->hasPathOperator()) {
        list.clear();
        mRoot->processTrimItems(list);
    }
}

std::unique_ptr<LOTContentItem>
LOTShapeLayerItem::createContentItem(LOTData *contentData)
{
    switch (contentData->type()) {
    case LOTData::Type::ShapeGroup: {
        return std::make_unique<LOTContentGroupItem>(
            static_cast<LOTShapeGroupData *>(contentData));
        break;
    }
    case LOTData::Type::Rect: {
        return std::make_unique<LOTRectItem>(static_cast<LOTRectData *>(contentData));
        break;
    }
    case LOTData::Type::Ellipse: {
        return std::make_unique<LOTEllipseItem>(static_cast<LOTEllipseData *>(contentData));
        break;
    }
    case LOTData::Type::Shape: {
        return std::make_unique<LOTShapeItem>(static_cast<LOTShapeData *>(contentData));
        break;
    }
    case LOTData::Type::Polystar: {
        return std::make_unique<LOTPolystarItem>(static_cast<LOTPolystarData *>(contentData));
        break;
    }
    case LOTData::Type::Fill: {
        return std::make_unique<LOTFillItem>(static_cast<LOTFillData *>(contentData));
        break;
    }
    case LOTData::Type::GFill: {
        return std::make_unique<LOTGFillItem>(static_cast<LOTGFillData *>(contentData));
        break;
    }
    case LOTData::Type::Stroke: {
        return std::make_unique<LOTStrokeItem>(static_cast<LOTStrokeData *>(contentData));
        break;
    }
    case LOTData::Type::GStroke: {
        return std::make_unique<LOTGStrokeItem>(static_cast<LOTGStrokeData *>(contentData));
        break;
    }
    case LOTData::Type::Repeater: {
        return std::make_unique<LOTRepeaterItem>(static_cast<LOTRepeaterData *>(contentData));
        break;
    }
    case LOTData::Type::Trim: {
        return std::make_unique<LOTTrimItem>(static_cast<LOTTrimData *>(contentData));
        break;
    }
    default:
        return nullptr;
        break;
    }
}

void LOTShapeLayerItem::updateContent()
{
    mRoot->update(frameNo(), combinedMatrix(), combinedAlpha(), flag());

    if (mLayerData->hasPathOperator()) {
        mRoot->applyTrim();
    }
}

void LOTShapeLayerItem::renderList(std::vector<VDrawable *> &list)
{
    if (!visible()) return;
    mRoot->renderList(list);
}

LOTContentGroupItem::LOTContentGroupItem(LOTShapeGroupData *data) : mData(data)
{
    addChildren(mData);
}

void LOTContentGroupItem::addChildren(LOTGroupData *data)
{
    if (!data) return;

    for (auto &i : data->mChildren) {
        auto content = LOTShapeLayerItem::createContentItem(i.get());
        if (content) {
            content->setParent(this);
            mContents.push_back(std::move(content));
        }
    }
}

void LOTContentGroupItem::update(int frameNo, const VMatrix &parentMatrix,
                                 float parentAlpha, const DirtyFlag &flag)
{
    VMatrix   m = parentMatrix;
    float     alpha = parentAlpha;
    DirtyFlag newFlag = flag;

    if (mData) {
        // update the matrix and the flag
        if ((flag & DirtyFlagBit::Matrix) ||
            !mData->mTransform->staticMatrix()) {
            newFlag |= DirtyFlagBit::Matrix;
        }
        m = mData->mTransform->matrix(frameNo);
        m *= parentMatrix;
        alpha *= mData->mTransform->opacity(frameNo);

        if (!vCompare(alpha, parentAlpha)) {
            newFlag |= DirtyFlagBit::Alpha;
        }
    }

    mMatrix = m;

    for (auto i = mContents.rbegin(); i != mContents.rend(); ++i) {
        (*i)->update(frameNo, m, alpha, newFlag);
    }
}

void LOTContentGroupItem::applyTrim()
{
    for (auto &i : mContents) {
        if (auto trim = dynamic_cast<LOTTrimItem *>(i.get())) {
            trim->update();
        } else if (auto group = dynamic_cast<LOTContentGroupItem *>(i.get())) {
            group->applyTrim();
        }
    }
}

void LOTContentGroupItem::renderList(std::vector<VDrawable *> &list)
{
    for (auto i = mContents.rbegin(); i != mContents.rend(); ++i) {
        (*i)->renderList(list);
    }
}

void LOTContentGroupItem::processPaintItems(
    std::vector<LOTPathDataItem *> &list)
{
    int curOpCount = list.size();
    for (auto &i : mContents) {
        if (auto pathNode = dynamic_cast<LOTPathDataItem *>(i.get())) {
            // add it to the list
            list.push_back(pathNode);
        } else if (auto paintNode = dynamic_cast<LOTPaintDataItem *>(i.get())) {
            // the node is a paint data node update the path list of the paint item.
            paintNode->addPathItems(list, curOpCount);
        } else if (auto groupNode =
                       dynamic_cast<LOTContentGroupItem *>(i.get())) {
            // update the groups node with current list
            groupNode->processPaintItems(list);
        }
    }
}

void LOTContentGroupItem::processTrimItems(
    std::vector<LOTPathDataItem *> &list)
{
    int curOpCount = list.size();
    for (auto &i : mContents) {
        if (auto pathNode = dynamic_cast<LOTPathDataItem *>(i.get())) {
            // add it to the list
            list.push_back(pathNode);
        } else if (auto trimNode = dynamic_cast<LOTTrimItem *>(i.get())) {
            // the node is a paint data node update the path list of the paint item.
            trimNode->addPathItems(list, curOpCount);
        } else if (auto groupNode =
                       dynamic_cast<LOTContentGroupItem *>(i.get())) {
            // update the groups node with current list
            groupNode->processTrimItems(list);
        }
    }
}

void LOTPathDataItem::update(int frameNo, const VMatrix &,
                             float, const DirtyFlag &flag)
{
    mPathChanged = false;

    // 1. update the local path if needed
    if (hasChanged(frameNo)) {
        updatePath(mLocalPath, frameNo);
        mPathChanged = true;
        mNeedUpdate = true;
    }

    mTemp = mLocalPath;

    // 3. compute the final path with parentMatrix
    if ((flag & DirtyFlagBit::Matrix) || mPathChanged) {
        mPathChanged = true;
    }
}

const VPath & LOTPathDataItem::finalPath()
{
    if (mPathChanged || mNeedUpdate) {
        mFinalPath.clone(mTemp);
        mFinalPath.transform(static_cast<LOTContentGroupItem *>(parent())->matrix());
        mNeedUpdate = false;
    }
    return mFinalPath;
}
LOTRectItem::LOTRectItem(LOTRectData *data)
    : LOTPathDataItem(data->isStatic()), mData(data)
{
}

void LOTRectItem::updatePath(VPath& path, int frameNo)
{
    VPointF pos = mData->mPos.value(frameNo);
    VPointF size = mData->mSize.value(frameNo);
    float   roundness = mData->mRound.value(frameNo);
    VRectF  r(pos.x() - size.x() / 2, pos.y() - size.y() / 2, size.x(),
             size.y());

    path.reset();
    path.addRoundRect(r, roundness, roundness, mData->direction());
    updateCache(frameNo, pos, size, roundness);
}

LOTEllipseItem::LOTEllipseItem(LOTEllipseData *data)
    : LOTPathDataItem(data->isStatic()), mData(data)
{
}

void LOTEllipseItem::updatePath(VPath& path, int frameNo)
{
    VPointF pos = mData->mPos.value(frameNo);
    VPointF size = mData->mSize.value(frameNo);
    VRectF  r(pos.x() - size.x() / 2, pos.y() - size.y() / 2, size.x(),
             size.y());

    path.reset();
    path.addOval(r, mData->direction());
    updateCache(frameNo, pos, size);
}

LOTShapeItem::LOTShapeItem(LOTShapeData *data)
    : LOTPathDataItem(data->isStatic()), mData(data)
{
}

void LOTShapeItem::updatePath(VPath& path, int frameNo)
{
    mData->mShape.value(frameNo).toPath(path);
}

LOTPolystarItem::LOTPolystarItem(LOTPolystarData *data)
    : LOTPathDataItem(data->isStatic()), mData(data)
{
}

void LOTPolystarItem::updatePath(VPath& path, int frameNo)
{
    VPointF pos = mData->mPos.value(frameNo);
    float   points = mData->mPointCount.value(frameNo);
    float   innerRadius = mData->mInnerRadius.value(frameNo);
    float   outerRadius = mData->mOuterRadius.value(frameNo);
    float   innerRoundness = mData->mInnerRoundness.value(frameNo);
    float   outerRoundness = mData->mOuterRoundness.value(frameNo);
    float   rotation = mData->mRotation.value(frameNo);

    path.reset();
    VMatrix m;

    if (mData->mType == LOTPolystarData::PolyType::Star) {
        path.addPolystar(points, innerRadius, outerRadius, innerRoundness,
                         outerRoundness, 0.0, 0.0, 0.0, mData->direction());
    } else {
        path.addPolygon(points, outerRadius, outerRoundness, 0.0, 0.0, 0.0,
                        mData->direction());
    }

    m.translate(pos.x(), pos.y()).rotate(rotation);
    m.rotate(rotation);
    path.transform(m);
    updateCache(frameNo, pos, points, innerRadius, outerRadius,
                innerRoundness, outerRoundness, rotation);
}

/*
 * PaintData Node handling
 *
 */
LOTPaintDataItem::LOTPaintDataItem(bool staticContent):mDrawable(std::make_unique<LOTDrawable>()),
                                                       mStaticContent(staticContent){}

void LOTPaintDataItem::update(int frameNo, const VMatrix &parentMatrix,
                              float parentAlpha, const DirtyFlag &flag)
{
    mRenderNodeUpdate = true;
    mParentAlpha = parentAlpha;
    mFlag = flag;
    mFrameNo = frameNo;

    updateContent(frameNo);
}

void LOTPaintDataItem::updateRenderNode()
{
    bool dirty = false;
    for (auto &i : mPathItems) {
        if (i->dirty()) {
            dirty = true;
            break;
        }
    }

    if (dirty) {
        mPath.reset();

        for (auto &i : mPathItems) {
            mPath.addPath(i->finalPath());
        }
        mDrawable->setPath(mPath);
    } else {
        if (mDrawable->mFlag & VDrawable::DirtyState::Path)
            mDrawable->mPath = mPath;
    }
}

void LOTPaintDataItem::renderList(std::vector<VDrawable *> &list)
{
    if (mRenderNodeUpdate) {
        updateRenderNode();
        LOTPaintDataItem::updateRenderNode();
        mRenderNodeUpdate = false;
    }
    list.push_back(mDrawable.get());
}


void LOTPaintDataItem::addPathItems(std::vector<LOTPathDataItem *> &list, int startOffset)
{
    std::copy(list.begin() + startOffset, list.end(), back_inserter(mPathItems));
}


LOTFillItem::LOTFillItem(LOTFillData *data)
    : LOTPaintDataItem(data->isStatic()), mData(data)
{
}

void LOTFillItem::updateContent(int frameNo)
{
    LottieColor c = mData->mColor.value(frameNo);
    float       opacity = mData->opacity(frameNo);
    mColor = c.toColor(opacity);
    mFillRule = mData->fillRule();
}

void LOTFillItem::updateRenderNode()
{
    VColor color = mColor;

    color.setAlpha(color.a * parentAlpha());
    VBrush brush(color);
    mDrawable->setBrush(brush);
    mDrawable->setFillRule(mFillRule);
}

LOTGFillItem::LOTGFillItem(LOTGFillData *data)
    : LOTPaintDataItem(data->isStatic()), mData(data)
{
}

void LOTGFillItem::updateContent(int frameNo)
{
    mData->update(mGradient, frameNo);
    mGradient->mMatrix = static_cast<LOTContentGroupItem *>(parent())->matrix();
    mFillRule = mData->fillRule();
}

void LOTGFillItem::updateRenderNode()
{
    mDrawable->setBrush(VBrush(mGradient.get()));
    mDrawable->setFillRule(mFillRule);
}

LOTStrokeItem::LOTStrokeItem(LOTStrokeData *data)
    : LOTPaintDataItem(data->isStatic()), mData(data)
{
    mDashArraySize = 0;
}

void LOTStrokeItem::updateContent(int frameNo)
{
    LottieColor c = mData->mColor.value(frameNo);
    float       opacity = mData->opacity(frameNo);
    mColor = c.toColor(opacity);
    mCap = mData->capStyle();
    mJoin = mData->joinStyle();
    mMiterLimit = mData->meterLimit();
    mWidth = mData->width(frameNo);
    if (mData->hasDashInfo()) {
        mDashArraySize = mData->getDashInfo(frameNo, mDashArray);
    }
}

static float getScale(const VMatrix &matrix)
{
    constexpr float SQRT_2 = 1.41421;
    VPointF         p1(0, 0);
    VPointF         p2(SQRT_2, SQRT_2);
    p1 = matrix.map(p1);
    p2 = matrix.map(p2);
    VPointF final = p2 - p1;

    return std::sqrt(final.x() * final.x() + final.y() * final.y()) / 2.0;
}

void LOTStrokeItem::updateRenderNode()
{
    VColor color = mColor;

    color.setAlpha(color.a * parentAlpha());
    VBrush brush(color);
    mDrawable->setBrush(brush);
    float scale = getScale(static_cast<LOTContentGroupItem *>(parent())->matrix());
    mDrawable->setStrokeInfo(mCap, mJoin, mMiterLimit,
                            mWidth * scale);
    if (mDashArraySize) {
        for (int i = 0 ; i < mDashArraySize ; i++)
            mDashArray[i] *= scale;
        mDrawable->setDashInfo(mDashArray, mDashArraySize);
    }
}

LOTGStrokeItem::LOTGStrokeItem(LOTGStrokeData *data)
    : LOTPaintDataItem(data->isStatic()), mData(data)
{
    mDashArraySize = 0;
}

void LOTGStrokeItem::updateContent(int frameNo)
{
    mData->update(mGradient, frameNo);
    mGradient->mMatrix = static_cast<LOTContentGroupItem *>(parent())->matrix();
    mCap = mData->capStyle();
    mJoin = mData->joinStyle();
    mMiterLimit = mData->meterLimit();
    mWidth = mData->width(frameNo);
    if (mData->hasDashInfo()) {
        mDashArraySize = mData->getDashInfo(frameNo, mDashArray);
    }
}

void LOTGStrokeItem::updateRenderNode()
{
    float scale = getScale(mGradient->mMatrix);
    mDrawable->setBrush(VBrush(mGradient.get()));
    mDrawable->setStrokeInfo(mCap, mJoin, mMiterLimit,
                            mWidth * scale);
    if (mDashArraySize) {
        for (int i = 0 ; i < mDashArraySize ; i++)
            mDashArray[i] *= scale;
        mDrawable->setDashInfo(mDashArray, mDashArraySize);
    }
}

LOTTrimItem::LOTTrimItem(LOTTrimData *data) : mData(data) {}

void LOTTrimItem::update(int frameNo, const VMatrix &/*parentMatrix*/,
                         float /*parentAlpha*/, const DirtyFlag &/*flag*/)
{
    mDirty = false;

    if (mCache.mFrameNo == frameNo) return;

    float   start = mData->start(frameNo);
    float   end = mData->end(frameNo);
    float   offset = mData->offset(frameNo);

    if (!(vCompare(mCache.mStart, start) && vCompare(mCache.mEnd, end) &&
          vCompare(mCache.mOffset, offset))) {
        mDirty = true;
        mCache.mStart = start;
        mCache.mEnd = end;
        mCache.mOffset = offset;
    }
    mCache.mFrameNo = frameNo;
}

void LOTTrimItem::update()
{
    // when both path and trim are not dirty
    if (!(mDirty || pathDirty())) return;

    //@TODO take the offset and trim type into account.
    for (auto &i : mPathItems) {
        VPathMesure pm;
        pm.setStart(mCache.mStart);
        pm.setEnd(mCache.mEnd);
        pm.setOffset(mCache.mOffset);
        i->updatePath(pm.trim(i->localPath()));
    }
}


void LOTTrimItem::addPathItems(std::vector<LOTPathDataItem *> &list, int startOffset)
{
    std::copy(list.begin() + startOffset, list.end(), back_inserter(mPathItems));
}


LOTRepeaterItem::LOTRepeaterItem(LOTRepeaterData *data) : mData(data) {}

void LOTRepeaterItem::update(int /*frameNo*/, const VMatrix &/*parentMatrix*/,
                             float /*parentAlpha*/, const DirtyFlag &/*flag*/)
{
}

void LOTRepeaterItem::renderList(std::vector<VDrawable *> &/*list*/) {}

void LOTDrawable::sync()
{
    mCNode.mFlag = ChangeFlagNone;
    if (mFlag & DirtyState::None) return;

    if (mFlag & DirtyState::Path) {
        const std::vector<VPath::Element> &elm = mPath.elements();
        const std::vector<VPointF> &       pts = mPath.points();
        const float *ptPtr = reinterpret_cast<const float *>(pts.data());
        const char * elmPtr = reinterpret_cast<const char *>(elm.data());
        mCNode.mPath.elmPtr = elmPtr;
        mCNode.mPath.elmCount = elm.size();
        mCNode.mPath.ptPtr = ptPtr;
        mCNode.mPath.ptCount = 2 * pts.size();
        mCNode.mFlag |= ChangeFlagPath;
    }

    if (mStroke.enable) {
        mCNode.mStroke.width = mStroke.width;
        mCNode.mStroke.meterLimit = mStroke.meterLimit;
        mCNode.mStroke.enable = 1;

        switch (mFillRule) {
        case FillRule::EvenOdd:
            mCNode.mFillRule = LOTFillRule::FillEvenOdd;
            break;
        default:
            mCNode.mFillRule = LOTFillRule::FillWinding;
            break;
        }

        switch (mStroke.cap) {
        case CapStyle::Flat:
            mCNode.mStroke.cap = LOTCapStyle::CapFlat;
            break;
        case CapStyle::Square:
            mCNode.mStroke.cap = LOTCapStyle::CapSquare;
            break;
        case CapStyle::Round:
            mCNode.mStroke.cap = LOTCapStyle::CapRound;
            break;
        default:
            mCNode.mStroke.cap = LOTCapStyle::CapFlat;
            break;
        }

        switch (mStroke.join) {
        case JoinStyle::Miter:
            mCNode.mStroke.join = LOTJoinStyle::JoinMiter;
            break;
        case JoinStyle::Bevel:
            mCNode.mStroke.join = LOTJoinStyle::JoinBevel;
            break;
        case JoinStyle::Round:
            mCNode.mStroke.join = LOTJoinStyle::JoinRound;
            break;
        default:
            mCNode.mStroke.join = LOTJoinStyle::JoinMiter;
            break;
        }

        mCNode.mStroke.dashArray = mStroke.mDash.data();
        mCNode.mStroke.dashArraySize = mStroke.mDash.size();

    } else {
        mCNode.mStroke.enable = 0;
    }

    switch (mBrush.type()) {
    case VBrush::Type::Solid:
        mCNode.mType = LOTBrushType::BrushSolid;
        mCNode.mColor.r = mBrush.mColor.r;
        mCNode.mColor.g = mBrush.mColor.g;
        mCNode.mColor.b = mBrush.mColor.b;
        mCNode.mColor.a = mBrush.mColor.a;
        break;
    case VBrush::Type::LinearGradient:
        mCNode.mType = LOTBrushType::BrushGradient;
        mCNode.mGradient.type = LOTGradientType::GradientLinear;
        mCNode.mGradient.start.x = mBrush.mGradient->linear.x1;
        mCNode.mGradient.start.y = mBrush.mGradient->linear.y1;
        mCNode.mGradient.end.x = mBrush.mGradient->linear.x2;
        mCNode.mGradient.end.y = mBrush.mGradient->linear.y2;
        break;
    case VBrush::Type::RadialGradient:
        mCNode.mType = LOTBrushType::BrushGradient;
        mCNode.mGradient.type = LOTGradientType::GradientRadial;
        mCNode.mGradient.center.x = mBrush.mGradient->radial.cx;
        mCNode.mGradient.center.y = mBrush.mGradient->radial.cy;
        mCNode.mGradient.focal.x = mBrush.mGradient->radial.fx;
        mCNode.mGradient.focal.y = mBrush.mGradient->radial.fy;
        mCNode.mGradient.cradius = mBrush.mGradient->radial.cradius;
        mCNode.mGradient.fradius = mBrush.mGradient->radial.fradius;
        break;
    default:
        break;
    }
}
