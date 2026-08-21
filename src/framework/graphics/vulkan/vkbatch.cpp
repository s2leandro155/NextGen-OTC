
// The whole Vulkan renderer is Win32-only for now (window surface), and the vulkan-headers
// dependency is windows-only in vcpkg.json. Outside Windows this file compiles to nothing,
// so it can sit unconditionally on the source list in CMakeLists.
#ifdef WIN32
#include "vkbatch.h"

#include <framework/core/logger.h>
#include <framework/core/resourcemanager.h>
#include <framework/graphics/image.h>

#include <algorithm>
#include <cstddef>
#include <cstring>
#include <exception>

namespace
{
    // Resource paths. The "/data/..." form works both when running from the working directory
    // (dev) and from the embedded assets.pak - the pak keeps files under the same prefixes.
    constexpr const char* kSpriteVertShaderPath = "/data/shaders/vulkan/sprite.vert.spv";
    constexpr const char* kSpriteFragShaderPath = "/data/shaders/vulkan/sprite.frag.spv";

    // The atlas layer side FOR THE DURATION OF THE STAGE 3 TEST. In production it will be 2048
    // from config.ini (mapAtlasSize), but then all the test images would fit in a single layer
    // and the multi-layer path would not be exercised at all. 512 forces several layers,
    // which PROVES that array-image growth and layer indexing work.
    constexpr uint32_t kTestAtlasSize = 512;

    // A dozen-plus different PNGs of DIFFERENT sizes - this is not a random set:
    // 256x256 (flags) forces several shelves and a layer overflow, while the small icons check
    // that shelf packing places them next to each other instead of wasting a whole shelf.
    constexpr const char* kTestImages[] = {
        "/data/images/flags/de.png",
        "/data/images/flags/en.png",
        "/data/images/flags/es.png",
        "/data/images/flags/pl.png",
        "/data/images/flags/pt.png",
        "/data/images/flags/sv.png",
        "/data/images/clienticon.png",
        "/data/images/back_clienticon.png",
        "/data/images/icons_big/icon-arbitrarymonster64x64.png",
        "/data/images/icons_big/icon_discord.png",
        "/data/images/icons_big/icon_youtube.png",
        "/data/images/icons_big/icon_twitch.png",
        "/data/images/icons_big/icon_forge.png",
        "/data/images/icons_big/icon-magicalarchive-additionalinfo.png",
        "/data/images/icons_big/icon-magicalarchive-combatstats.png",
        "/data/images/icons_big/icon-magicalarchive-runeinfo.png",
        "/data/images/icons_big/icon-fusion.png",
        "/data/images/icons_big/icon-conversion.png",
        "/data/images/icons_big/icon-history.png",
    };

    // Since stage 4 VkSpriteVertex lives in the header (the feeder writes vertices directly).

    // Must match the push_constant block in sprite.vert byte for byte.
    struct VkSpritePushConstants
    {
        float invHalfSize[2];
    };
}

bool VkSpriteBatch::fail(const std::string& reason)
{
    m_error = reason;
    g_logger.warning("[vulkan] sprite batch: {} - the context keeps running, but without the batch", reason);
    terminate();
    return false;
}

bool VkSpriteBatch::init(VkPhysicalDevice physicalDevice, VkDevice device, VkRenderPass renderPass,
                         VkQueue graphicsQueue, VkCommandPool commandPool, const uint32_t framesInFlight,
                         const uint32_t atlasSize)
{
    if (m_ready)
        return true;

    if (physicalDevice == VK_NULL_HANDLE || device == VK_NULL_HANDLE || renderPass == VK_NULL_HANDLE ||
        graphicsQueue == VK_NULL_HANDLE || commandPool == VK_NULL_HANDLE || framesInFlight == 0)
        return fail("incomplete context passed to the sprite batch");

    m_physicalDevice = physicalDevice;
    m_device = device;
    m_renderPass = renderPass;
    m_graphicsQueue = graphicsQueue;
    m_commandPool = commandPool;

    if (!loadFunctions())
        return false;

    if (!createShaderModules())
        return false;

    if (!m_atlas.init(physicalDevice, device, graphicsQueue, commandPool,
                      atlasSize > 0 ? atlasSize : kTestAtlasSize))
        return fail("the atlas failed to initialize: " + m_atlas.getError());

    if (!loadTestImages())
        return false;

    if (!createIndexBuffer())
        return false;

    if (!createVertexBuffers(framesInFlight))
        return false;

    if (!createDescriptors())
        return false;

    // We write the descriptor RIGHT NOW, not at the first frame - the atlas is complete,
    // so its view is already final and the first frame does not have to wait for the device.
    if (!syncDescriptor())
        return fail("failed to write the atlas into the descriptor");

    if (!createPipeline())
        return false;

    m_ready = true;

    // Diagnostic line required by stage 3: how many tiles, how many layers, how much card memory.
    g_logger.info("[vulkan] atlas ready: {} tiles, {} layers, layer {}x{}, VRAM {:.2f} MB, occupancy {:.1f}%",
                  m_atlas.getTileCount(), m_atlas.getLayerCount(), m_atlas.getSize(), m_atlas.getSize(),
                  static_cast<double>(m_atlas.getGpuBytes()) / (1024.0 * 1024.0),
                  m_atlas.getOccupancy() * 100.0f);

    return true;
}

bool VkSpriteBatch::loadFunctions()
{
    const auto fn = [this](const char* name) { return vkGetDeviceProcAddr(m_device, name); };

    m_vkCreateShaderModule = reinterpret_cast<PFN_vkCreateShaderModule>(fn("vkCreateShaderModule"));
    m_vkDestroyShaderModule = reinterpret_cast<PFN_vkDestroyShaderModule>(fn("vkDestroyShaderModule"));

    m_vkCreateBuffer = reinterpret_cast<PFN_vkCreateBuffer>(fn("vkCreateBuffer"));
    m_vkDestroyBuffer = reinterpret_cast<PFN_vkDestroyBuffer>(fn("vkDestroyBuffer"));
    m_vkGetBufferMemoryRequirements = reinterpret_cast<PFN_vkGetBufferMemoryRequirements>(fn("vkGetBufferMemoryRequirements"));
    m_vkBindBufferMemory = reinterpret_cast<PFN_vkBindBufferMemory>(fn("vkBindBufferMemory"));

    m_vkAllocateMemory = reinterpret_cast<PFN_vkAllocateMemory>(fn("vkAllocateMemory"));
    m_vkFreeMemory = reinterpret_cast<PFN_vkFreeMemory>(fn("vkFreeMemory"));
    m_vkMapMemory = reinterpret_cast<PFN_vkMapMemory>(fn("vkMapMemory"));
    m_vkUnmapMemory = reinterpret_cast<PFN_vkUnmapMemory>(fn("vkUnmapMemory"));

    m_vkCreateDescriptorSetLayout = reinterpret_cast<PFN_vkCreateDescriptorSetLayout>(fn("vkCreateDescriptorSetLayout"));
    m_vkDestroyDescriptorSetLayout = reinterpret_cast<PFN_vkDestroyDescriptorSetLayout>(fn("vkDestroyDescriptorSetLayout"));
    m_vkCreateDescriptorPool = reinterpret_cast<PFN_vkCreateDescriptorPool>(fn("vkCreateDescriptorPool"));
    m_vkDestroyDescriptorPool = reinterpret_cast<PFN_vkDestroyDescriptorPool>(fn("vkDestroyDescriptorPool"));
    m_vkAllocateDescriptorSets = reinterpret_cast<PFN_vkAllocateDescriptorSets>(fn("vkAllocateDescriptorSets"));
    m_vkUpdateDescriptorSets = reinterpret_cast<PFN_vkUpdateDescriptorSets>(fn("vkUpdateDescriptorSets"));

    m_vkCreatePipelineLayout = reinterpret_cast<PFN_vkCreatePipelineLayout>(fn("vkCreatePipelineLayout"));
    m_vkDestroyPipelineLayout = reinterpret_cast<PFN_vkDestroyPipelineLayout>(fn("vkDestroyPipelineLayout"));
    m_vkCreateGraphicsPipelines = reinterpret_cast<PFN_vkCreateGraphicsPipelines>(fn("vkCreateGraphicsPipelines"));
    m_vkDestroyPipeline = reinterpret_cast<PFN_vkDestroyPipeline>(fn("vkDestroyPipeline"));

    m_vkCmdBindPipeline = reinterpret_cast<PFN_vkCmdBindPipeline>(fn("vkCmdBindPipeline"));
    m_vkCmdBindVertexBuffers = reinterpret_cast<PFN_vkCmdBindVertexBuffers>(fn("vkCmdBindVertexBuffers"));
    m_vkCmdBindIndexBuffer = reinterpret_cast<PFN_vkCmdBindIndexBuffer>(fn("vkCmdBindIndexBuffer"));
    m_vkCmdBindDescriptorSets = reinterpret_cast<PFN_vkCmdBindDescriptorSets>(fn("vkCmdBindDescriptorSets"));
    m_vkCmdSetViewport = reinterpret_cast<PFN_vkCmdSetViewport>(fn("vkCmdSetViewport"));
    m_vkCmdSetScissor = reinterpret_cast<PFN_vkCmdSetScissor>(fn("vkCmdSetScissor"));
    m_vkCmdPushConstants = reinterpret_cast<PFN_vkCmdPushConstants>(fn("vkCmdPushConstants"));
    m_vkCmdDrawIndexed = reinterpret_cast<PFN_vkCmdDrawIndexed>(fn("vkCmdDrawIndexed"));
    m_vkCmdDraw = reinterpret_cast<PFN_vkCmdDraw>(fn("vkCmdDraw"));

    if (!m_vkCreateShaderModule || !m_vkDestroyShaderModule ||
        !m_vkCreateBuffer || !m_vkDestroyBuffer || !m_vkGetBufferMemoryRequirements || !m_vkBindBufferMemory ||
        !m_vkAllocateMemory || !m_vkFreeMemory || !m_vkMapMemory || !m_vkUnmapMemory ||
        !m_vkCreateDescriptorSetLayout || !m_vkDestroyDescriptorSetLayout ||
        !m_vkCreateDescriptorPool || !m_vkDestroyDescriptorPool ||
        !m_vkAllocateDescriptorSets || !m_vkUpdateDescriptorSets ||
        !m_vkCreatePipelineLayout || !m_vkDestroyPipelineLayout ||
        !m_vkCreateGraphicsPipelines || !m_vkDestroyPipeline ||
        !m_vkCmdBindPipeline || !m_vkCmdBindVertexBuffers || !m_vkCmdBindIndexBuffer ||
        !m_vkCmdBindDescriptorSets || !m_vkCmdSetViewport || !m_vkCmdSetScissor ||
        !m_vkCmdPushConstants || !m_vkCmdDrawIndexed || !m_vkCmdDraw)
        return fail("missing functions required for batched drawing");

    // INSTANCE functions, not device ones - from vkloader's globals.
    if (!vkGetPhysicalDeviceMemoryProperties || !vkDeviceWaitIdle)
        return fail("missing instance functions required by the batch");

    return true;
}

VkShaderModule VkSpriteBatch::loadShader(const std::string& path)
{
    std::string code;

    // readFileContents throws when the file is missing. We catch it here because a missing .spv
    // is supposed to degrade the renderer, not crash the client.
    try {
        code = g_resources.readFileContents(path);
    } catch (const std::exception& e) {
        g_logger.warning("[vulkan] cannot load {}: {}", path, e.what());
        return VK_NULL_HANDLE;
    }

    // SPIR-V is a stream of 32-bit words: the size must be a multiple of 4, and the first word
    // is the magic number 0x07230203. We check both so a random file never reaches
    // the driver (its own validation can end in a process crash).
    if (code.size() < 4 || (code.size() % 4) != 0) {
        g_logger.warning("[vulkan] {} has size {} - this is not valid SPIR-V", path, code.size());
        return VK_NULL_HANDLE;
    }

    uint32_t magic = 0;
    std::memcpy(&magic, code.data(), sizeof(magic));
    if (magic != 0x07230203u) {
        g_logger.warning("[vulkan] {} does not start with the SPIR-V magic number", path);
        return VK_NULL_HANDLE;
    }

    // We copy into a uint32_t vector because std::string does not guarantee 4-byte alignment,
    // and pCode is a pointer to uint32_t.
    std::vector<uint32_t> words(code.size() / 4);
    std::memcpy(words.data(), code.data(), code.size());

    VkShaderModuleCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    info.codeSize = code.size();
    info.pCode = words.data();

    VkShaderModule module = VK_NULL_HANDLE;
    if (m_vkCreateShaderModule(m_device, &info, nullptr, &module) != VK_SUCCESS) {
        g_logger.warning("[vulkan] the driver rejected shader module {}", path);
        return VK_NULL_HANDLE;
    }

    return module;
}

bool VkSpriteBatch::createShaderModules()
{
    m_vertShader = loadShader(kSpriteVertShaderPath);
    if (m_vertShader == VK_NULL_HANDLE)
        return fail("missing sprite vertex shader module");

    m_fragShader = loadShader(kSpriteFragShaderPath);
    if (m_fragShader == VK_NULL_HANDLE)
        return fail("missing sprite fragment shader module");

    return true;
}

uint32_t VkSpriteBatch::findMemoryType(const uint32_t typeFilter, const VkMemoryPropertyFlags properties) const
{
    VkPhysicalDeviceMemoryProperties memProps{};
    vkGetPhysicalDeviceMemoryProperties(m_physicalDevice, &memProps);

    for (uint32_t i = 0; i < memProps.memoryTypeCount; ++i) {
        if ((typeFilter & (1u << i)) && (memProps.memoryTypes[i].propertyFlags & properties) == properties)
            return i;
    }

    return UINT32_MAX;
}

bool VkSpriteBatch::createBuffer(const VkDeviceSize size, const VkBufferUsageFlags usage,
                                 const VkMemoryPropertyFlags properties,
                                 VkBuffer& buffer, VkDeviceMemory& memory)
{
    VkBufferCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    info.size = size;
    info.usage = usage;
    info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    if (m_vkCreateBuffer(m_device, &info, nullptr, &buffer) != VK_SUCCESS)
        return false;

    VkMemoryRequirements req{};
    m_vkGetBufferMemoryRequirements(m_device, buffer, &req);

    const uint32_t typeIndex = findMemoryType(req.memoryTypeBits, properties);
    if (typeIndex == UINT32_MAX)
        return false;

    VkMemoryAllocateInfo alloc{};
    alloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    alloc.allocationSize = req.size;
    alloc.memoryTypeIndex = typeIndex;

    if (m_vkAllocateMemory(m_device, &alloc, nullptr, &memory) != VK_SUCCESS)
        return false;

    return m_vkBindBufferMemory(m_device, buffer, memory, 0) == VK_SUCCESS;
}

bool VkSpriteBatch::loadTestImages()
{
    m_testSlots.clear();

    for (const char* path : kTestImages) {
        // We use the existing Image class to avoid duplicating the PNG decoder - it is the same
        // loading path the OpenGL renderer uses.
        ImagePtr image;
        try {
            image = Image::load(path);
        } catch (const std::exception& e) {
            g_logger.warning("[vulkan] batch: failed to load {}: {}", path, e.what());
            continue;
        }

        if (!image) {
            g_logger.warning("[vulkan] batch: failed to load {}", path);
            continue;
        }

        const VkAtlasSlot slot = m_atlas.add(image);
        if (slot.valid)
            m_testSlots.push_back(slot);
    }

    // One upload for the whole set - that is the point of batching.
    if (!m_atlas.flush())
        return fail("failed to upload the test images to the atlas: " + m_atlas.getError());

    if (m_testSlots.empty())
        return fail("no test image made it into the atlas");

    return true;
}

bool VkSpriteBatch::createIndexBuffer()
{
    // Tile n occupies vertices 4n..4n+3 and always the same two triangles sharing a diagonal.
    // Thanks to that the index buffer is CONSTANT: only the vertices change each frame.
    std::vector<uint32_t> indices(static_cast<size_t>(kMaxQuads) * 6);
    for (uint32_t q = 0; q < kMaxQuads; ++q) {
        const uint32_t base = q * 4;
        uint32_t* dst = indices.data() + static_cast<size_t>(q) * 6;
        dst[0] = base + 0;
        dst[1] = base + 1;
        dst[2] = base + 2;
        dst[3] = base + 2;
        dst[4] = base + 3;
        dst[5] = base + 0;
    }

    const VkDeviceSize bytes = indices.size() * sizeof(uint32_t);

    // Host-visible memory even though the data is constant: it is 196 KB uploaded once.
    // A staging buffer + copy would bring an unmeasurable gain here, and would cost code and one
    // trip through the queue. For the atlas the decision goes the other way and a staging buffer
    // IS used there.
    if (!createBuffer(bytes, VK_BUFFER_USAGE_INDEX_BUFFER_BIT,
                      VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                      m_indexBuffer, m_indexMemory))
        return fail("failed to create the index buffer");

    void* mapped = nullptr;
    if (m_vkMapMemory(m_device, m_indexMemory, 0, bytes, 0, &mapped) != VK_SUCCESS)
        return fail("failed to map the index buffer");

    std::memcpy(mapped, indices.data(), static_cast<size_t>(bytes));
    m_vkUnmapMemory(m_device, m_indexMemory);

    return true;
}

bool VkSpriteBatch::createVertexBuffers(const uint32_t framesInFlight)
{
    // The buffer must hold the larger of the two modes: test scene tiles (4 vertices per tile,
    // drawn with indices) or the raw triangles of the external mode (stage 4, without indices).
    const VkDeviceSize bytes = static_cast<VkDeviceSize>(
        std::max<uint32_t>(kMaxQuads * 4, kMaxVertices)) * sizeof(VkSpriteVertex);

    m_vertexBuffers.resize(framesInFlight, VK_NULL_HANDLE);
    m_vertexMemories.resize(framesInFlight, VK_NULL_HANDLE);
    m_vertexMapped.resize(framesInFlight, nullptr);

    for (uint32_t i = 0; i < framesInFlight; ++i) {
        if (!createBuffer(bytes, VK_BUFFER_USAGE_VERTEX_BUFFER_BIT,
                          VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT,
                          m_vertexBuffers[i], m_vertexMemories[i]))
            return fail("failed to create the dynamic vertex buffer");

        // We map ONCE and never unmap for the object's lifetime. Mapping and unmapping
        // every frame is a driver call that in the worst case can synchronize
        // the CPU with the card - and HOST_COHERENT guarantees the write is visible without
        // manually flushing the range.
        if (m_vkMapMemory(m_device, m_vertexMemories[i], 0, bytes, 0, &m_vertexMapped[i]) != VK_SUCCESS)
            return fail("failed to persistently map the vertex buffer");
    }

    return true;
}

bool VkSpriteBatch::createDescriptors()
{
    VkDescriptorSetLayoutBinding binding{};
    binding.binding = 0;
    binding.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    binding.descriptorCount = 1;
    binding.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;

    VkDescriptorSetLayoutCreateInfo layoutInfo{};
    layoutInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    layoutInfo.bindingCount = 1;
    layoutInfo.pBindings = &binding;

    if (m_vkCreateDescriptorSetLayout(m_device, &layoutInfo, nullptr, &m_descriptorLayout) != VK_SUCCESS)
        return fail("failed to create the descriptor set layout");

    VkDescriptorPoolSize poolSize{};
    poolSize.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    poolSize.descriptorCount = 1;

    VkDescriptorPoolCreateInfo poolInfo{};
    poolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    // ONE set for the renderer's whole lifetime - and that is the entire point of stage 3.
    // Without the atlas we would need one set per texture, i.e. tens of thousands.
    poolInfo.maxSets = 1;
    poolInfo.poolSizeCount = 1;
    poolInfo.pPoolSizes = &poolSize;

    if (m_vkCreateDescriptorPool(m_device, &poolInfo, nullptr, &m_descriptorPool) != VK_SUCCESS)
        return fail("failed to create the descriptor pool");

    VkDescriptorSetAllocateInfo alloc{};
    alloc.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    alloc.descriptorPool = m_descriptorPool;
    alloc.descriptorSetCount = 1;
    alloc.pSetLayouts = &m_descriptorLayout;

    if (m_vkAllocateDescriptorSets(m_device, &alloc, &m_descriptorSet) != VK_SUCCESS)
        return fail("failed to allocate the descriptor set");

    return true;
}

bool VkSpriteBatch::syncDescriptor()
{
    if (m_descriptorSet == VK_NULL_HANDLE || !m_atlas.isReady())
        return false;

    const uint32_t generation = m_atlas.getGeneration();
    if (generation == m_descriptorGeneration)
        return true;

    // Atlas growth recreates the view, so the descriptor set points at an object that no longer
    // exists. Overwriting a set that may be read by a frame in flight is an error - hence
    // the wait for the device. This happens ONLY when adding a layer (i.e. while
    // loading assets), never in the steady frame loop. The first write (at init)
    // is free, because there is no frame in flight yet.
    if (m_descriptorGeneration != UINT32_MAX)
        vkDeviceWaitIdle(m_device);

    VkDescriptorImageInfo imageInfo{};
    imageInfo.sampler = m_atlas.getSampler();
    imageInfo.imageView = m_atlas.getView();
    imageInfo.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;

    if (imageInfo.sampler == VK_NULL_HANDLE || imageInfo.imageView == VK_NULL_HANDLE)
        return false;

    VkWriteDescriptorSet write{};
    write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    write.dstSet = m_descriptorSet;
    write.dstBinding = 0;
    write.descriptorCount = 1;
    write.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    write.pImageInfo = &imageInfo;

    m_vkUpdateDescriptorSets(m_device, 1, &write, 0, nullptr);
    m_descriptorGeneration = generation;

    return true;
}

bool VkSpriteBatch::createPipeline()
{
    VkPipelineShaderStageCreateInfo stages[2]{};
    stages[0].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stages[0].stage = VK_SHADER_STAGE_VERTEX_BIT;
    stages[0].module = m_vertShader;
    stages[0].pName = "main";
    stages[1].sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    stages[1].stage = VK_SHADER_STAGE_FRAGMENT_BIT;
    stages[1].module = m_fragShader;
    stages[1].pName = "main";

    VkVertexInputBindingDescription bindingDesc{};
    bindingDesc.binding = 0;
    bindingDesc.stride = sizeof(VkSpriteVertex);
    bindingDesc.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

    VkVertexInputAttributeDescription attrs[4]{};
    attrs[0].location = 0;
    attrs[0].binding = 0;
    attrs[0].format = VK_FORMAT_R32G32_SFLOAT;
    attrs[0].offset = offsetof(VkSpriteVertex, pos);
    attrs[1].location = 1;
    attrs[1].binding = 0;
    attrs[1].format = VK_FORMAT_R32G32_SFLOAT;
    attrs[1].offset = offsetof(VkSpriteVertex, uv);
    attrs[2].location = 2;
    attrs[2].binding = 0;
    attrs[2].format = VK_FORMAT_R32_SFLOAT;
    attrs[2].offset = offsetof(VkSpriteVertex, layer);
    attrs[3].location = 3;
    attrs[3].binding = 0;
    // UNORM, not UINT: the hardware divides by 255 itself, so the color takes 4 bytes instead
    // of 16, and the shader receives a ready [0,1]. At 8192 tiles that is 393 KB of difference
    // per frame.
    attrs[3].format = VK_FORMAT_R8G8B8A8_UNORM;
    attrs[3].offset = offsetof(VkSpriteVertex, color);

    VkPipelineVertexInputStateCreateInfo vertexInput{};
    vertexInput.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    vertexInput.vertexBindingDescriptionCount = 1;
    vertexInput.pVertexBindingDescriptions = &bindingDesc;
    vertexInput.vertexAttributeDescriptionCount = 4;
    vertexInput.pVertexAttributeDescriptions = attrs;

    VkPipelineInputAssemblyStateCreateInfo assembly{};
    assembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    assembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;

    // The viewport and scissor are DYNAMIC, so here we only give their count. If they were part
    // of the pipeline, every window resize would require rebuilding the whole VkPipeline.
    VkPipelineViewportStateCreateInfo viewportState{};
    viewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    viewportState.viewportCount = 1;
    viewportState.scissorCount = 1;

    const VkDynamicState dynamicStates[] = { VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };

    VkPipelineDynamicStateCreateInfo dynamicState{};
    dynamicState.sType = VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
    dynamicState.dynamicStateCount = 2;
    dynamicState.pDynamicStates = dynamicStates;

    VkPipelineRasterizationStateCreateInfo raster{};
    raster.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    raster.polygonMode = VK_POLYGON_MODE_FILL;
    raster.cullMode = VK_CULL_MODE_NONE;
    raster.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
    raster.lineWidth = 1.0f;

    VkPipelineMultisampleStateCreateInfo multisample{};
    multisample.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    multisample.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;

    VkPipelineColorBlendAttachmentState blendAttachment{};
    blendAttachment.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT |
                                     VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
    // Alpha blending enabled, because the client's sprites have transparent backgrounds.
    blendAttachment.blendEnable = VK_TRUE;
    blendAttachment.srcColorBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA;
    blendAttachment.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    blendAttachment.colorBlendOp = VK_BLEND_OP_ADD;
    blendAttachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
    blendAttachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    blendAttachment.alphaBlendOp = VK_BLEND_OP_ADD;

    VkPipelineColorBlendStateCreateInfo blend{};
    blend.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    blend.attachmentCount = 1;
    blend.pAttachments = &blendAttachment;

    VkPushConstantRange pushRange{};
    pushRange.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
    pushRange.offset = 0;
    pushRange.size = sizeof(VkSpritePushConstants);

    VkPipelineLayoutCreateInfo layoutInfo{};
    layoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    layoutInfo.setLayoutCount = 1;
    layoutInfo.pSetLayouts = &m_descriptorLayout;
    layoutInfo.pushConstantRangeCount = 1;
    layoutInfo.pPushConstantRanges = &pushRange;

    if (m_vkCreatePipelineLayout(m_device, &layoutInfo, nullptr, &m_pipelineLayout) != VK_SUCCESS)
        return fail("failed to create the pipeline layout");

    VkGraphicsPipelineCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    info.stageCount = 2;
    info.pStages = stages;
    info.pVertexInputState = &vertexInput;
    info.pInputAssemblyState = &assembly;
    info.pViewportState = &viewportState;
    info.pRasterizationState = &raster;
    info.pMultisampleState = &multisample;
    info.pColorBlendState = &blend;
    info.pDynamicState = &dynamicState;
    info.layout = m_pipelineLayout;
    // The pipeline is tied to the render pass, not the swapchain - VkContext's render pass survives
    // swapchain recreation, so the pipeline also needs no rebuild on window resize.
    info.renderPass = m_renderPass;
    info.subpass = 0;

    if (m_vkCreateGraphicsPipelines(m_device, VK_NULL_HANDLE, 1, &info, nullptr, &m_pipeline) != VK_SUCCESS)
        return fail("failed to create the sprite graphics pipeline");

    // The MULTIPLY variant - an identical pipeline, differing only in blend state. It matches GL's
    // glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA) (the alpha channel inherits the same
    // factors, with DST_COLOR turning into DST_ALPHA - exactly what glBlendFunc does).
    blendAttachment.srcColorBlendFactor = VK_BLEND_FACTOR_DST_COLOR;
    blendAttachment.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
    blendAttachment.srcAlphaBlendFactor = VK_BLEND_FACTOR_DST_ALPHA;
    blendAttachment.dstAlphaBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;

    if (m_vkCreateGraphicsPipelines(m_device, VK_NULL_HANDLE, 1, &info, nullptr, &m_pipelineMultiply) != VK_SUCCESS)
        return fail("failed to create the MULTIPLY pipeline");

    return true;
}

void VkSpriteBatch::begin()
{
    // clear() keeps the capacity, so after a few frames building the list stops allocating entirely.
    m_quads.clear();
}

void VkSpriteBatch::beginExternal(const VkExtent2D& extent)
{
    m_vertices.clear();
    m_segments.clear();

    // The first segment covers the full screen - setScissor will replace it in place as long as
    // not a single vertex has arrived.
    Segment segment;
    segment.scissor = VkRect2D{ { 0, 0 }, extent };
    m_segments.push_back(segment);

    m_externallyFed = true;
}

void VkSpriteBatch::setScissor(const VkRect2D& scissor)
{
    if (m_segments.empty()) {
        Segment segment;
        segment.scissor = scissor;
        m_segments.push_back(segment);
        return;
    }

    Segment& current = m_segments.back();

    const bool same = current.scissor.offset.x == scissor.offset.x &&
                      current.scissor.offset.y == scissor.offset.y &&
                      current.scissor.extent.width == scissor.extent.width &&
                      current.scissor.extent.height == scissor.extent.height;
    if (same)
        return;

    // An empty segment can be retargeted in place - we only create a new one when it already has content.
    if (current.count == 0) {
        current.scissor = scissor;
        return;
    }

    Segment segment;
    segment.first = current.first + current.count;
    segment.scissor = scissor;
    segment.pipeline = current.pipeline;
    m_segments.push_back(segment);
}

void VkSpriteBatch::setPipeline(const uint8_t pipelineIndex)
{
    if (m_segments.empty())
        return;

    Segment& current = m_segments.back();
    if (current.pipeline == pipelineIndex)
        return;

    if (current.count == 0) {
        current.pipeline = pipelineIndex;
        return;
    }

    Segment segment;
    segment.first = current.first + current.count;
    segment.scissor = current.scissor;
    segment.pipeline = pipelineIndex;
    m_segments.push_back(segment);
}

void VkSpriteBatch::abortExternal()
{
    m_vertices.clear();
    m_segments.clear();
    m_externallyFed = false;
}

namespace
{
    // Working clipping vertex: position + uv. Layer and color are constant within
    // a single triangle (the feeder emits them per object), so we do not interpolate them.
    struct ClipVertex
    {
        float x, y, u, v;
    };

    // Sutherland-Hodgman against a single axis-aligned half-plane; uv interpolated along the edge.
    void clipHalfplane(std::vector<ClipVertex>& poly, std::vector<ClipVertex>& scratch,
                       const int axis, const bool keepGreater, const float edge)
    {
        scratch.clear();
        const size_t n = poly.size();
        for (size_t i = 0; i < n; ++i) {
            const ClipVertex& a = poly[i];
            const ClipVertex& b = poly[(i + 1) % n];
            const float va = axis == 0 ? a.x : a.y;
            const float vb = axis == 0 ? b.x : b.y;
            const bool inA = keepGreater ? va >= edge : va <= edge;
            const bool inB = keepGreater ? vb >= edge : vb <= edge;

            if (inA)
                scratch.push_back(a);

            if (inA != inB) {
                const float t = (edge - va) / (vb - va);
                scratch.push_back(ClipVertex{ a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t,
                                              a.u + (b.u - a.u) * t, a.v + (b.v - a.v) * t });
            }
        }
        poly.swap(scratch);
    }

    struct HalfplaneSpec
    {
        int axis;          // 0 = X, 1 = Y
        bool keepGreater;  // true: v >= edge is kept, false: v <= edge is kept
        float edge;
    };

    // Clips a triangle to the conjunction of half-planes and appends the result (a fan) to out.
    void emitClippedTriangle(const VkSpriteVertex* tri, const HalfplaneSpec* specs, const int specCount,
                             std::vector<VkSpriteVertex>& out)
    {
        static std::vector<ClipVertex> poly;
        static std::vector<ClipVertex> scratch;

        poly.clear();
        for (int i = 0; i < 3; ++i)
            poly.push_back(ClipVertex{ tri[i].pos[0], tri[i].pos[1], tri[i].uv[0], tri[i].uv[1] });

        for (int s = 0; s < specCount && poly.size() >= 3; ++s)
            clipHalfplane(poly, scratch, specs[s].axis, specs[s].keepGreater, specs[s].edge);

        if (poly.size() < 3)
            return;

        for (size_t i = 1; i + 1 < poly.size(); ++i) {
            const ClipVertex* fan[3] = { &poly[0], &poly[i], &poly[i + 1] };
            for (const ClipVertex* cv : fan) {
                VkSpriteVertex v = tri[0]; // layer and color from the original
                v.pos[0] = cv->x;
                v.pos[1] = cv->y;
                v.uv[0] = cv->u;
                v.uv[1] = cv->v;
                out.push_back(v);
            }
        }
    }
}

void VkSpriteBatch::punchRect(const uint32_t fromVertex, const float x0, const float y0,
                              const float x1, const float y1)
{
    if (x1 <= x0 || y1 <= y0 || m_segments.empty())
        return;

    const uint32_t total = static_cast<uint32_t>(m_vertices.size());
    if (fromVertex >= total)
        return;

    // The segments cover the vertex vector exactly and in order (allocVertices always appends
    // to the last one), so the whole thing can be rebuilt triangle by triangle, recomputing
    // each segment's first/count.
    std::vector<VkSpriteVertex> out;
    out.reserve(m_vertices.size() + 64);

    for (Segment& segment : m_segments) {
        const uint32_t segFirst = segment.first;
        const uint32_t segEnd = segment.first + segment.count;
        const uint32_t newFirst = static_cast<uint32_t>(out.size());

        for (uint32_t i = segFirst; i + 3 <= segEnd; i += 3) {
            const VkSpriteVertex* tri = m_vertices.data() + i;

            if (i < fromVertex) {
                out.push_back(tri[0]);
                out.push_back(tri[1]);
                out.push_back(tri[2]);
                continue;
            }

            const float minX = std::min({ tri[0].pos[0], tri[1].pos[0], tri[2].pos[0] });
            const float maxX = std::max({ tri[0].pos[0], tri[1].pos[0], tri[2].pos[0] });
            const float minY = std::min({ tri[0].pos[1], tri[1].pos[1], tri[2].pos[1] });
            const float maxY = std::max({ tri[0].pos[1], tri[1].pos[1], tri[2].pos[1] });

            // Entirely outside the hole - stays unchanged.
            if (maxX <= x0 || minX >= x1 || maxY <= y0 || minY >= y1) {
                out.push_back(tri[0]);
                out.push_back(tri[1]);
                out.push_back(tri[2]);
                continue;
            }

            // Entirely inside - disappears.
            if (minX >= x0 && maxX <= x1 && minY >= y0 && maxY <= y1)
                continue;

            // Partial intersection: what remains is the union of four disjoint bands around
            // the hole (left, right, plus top and bottom limited to the hole's width).
            const HalfplaneSpec left[] = { { 0, false, x0 } };
            const HalfplaneSpec right[] = { { 0, true, x1 } };
            const HalfplaneSpec top[] = { { 0, true, x0 }, { 0, false, x1 }, { 1, false, y0 } };
            const HalfplaneSpec bottom[] = { { 0, true, x0 }, { 0, false, x1 }, { 1, true, y1 } };

            emitClippedTriangle(tri, left, 1, out);
            emitClippedTriangle(tri, right, 1, out);
            emitClippedTriangle(tri, top, 3, out);
            emitClippedTriangle(tri, bottom, 3, out);
        }

        segment.first = newFirst;
        segment.count = static_cast<uint32_t>(out.size()) - newFirst;
    }

    m_vertices.swap(out);
}

VkSpriteVertex* VkSpriteBatch::allocVertices(const uint32_t count)
{
    if (count == 0 || m_segments.empty())
        return nullptr;

    const size_t offset = m_vertices.size();
    if (offset + count > kMaxVertices) {
        m_droppedVertices += count;
        return nullptr;
    }

    m_vertices.resize(offset + count);
    m_segments.back().count += count;
    return m_vertices.data() + offset;
}

void VkSpriteBatch::drawSprite(const float x, const float y, const float w, const float h,
                               const VkAtlasSlot& slot, const uint32_t rgba)
{
    if (!slot.valid)
        return;

    VkSpriteQuad quad;
    quad.x = x;
    quad.y = y;
    quad.w = w;
    quad.h = h;
    quad.uvMin[0] = slot.uvMin[0];
    quad.uvMin[1] = slot.uvMin[1];
    quad.uvMax[0] = slot.uvMax[0];
    quad.uvMax[1] = slot.uvMax[1];
    quad.layer = static_cast<float>(slot.layer);
    quad.color[0] = static_cast<uint8_t>((rgba >> 24) & 0xFFu);
    quad.color[1] = static_cast<uint8_t>((rgba >> 16) & 0xFFu);
    quad.color[2] = static_cast<uint8_t>((rgba >> 8) & 0xFFu);
    quad.color[3] = static_cast<uint8_t>(rgba & 0xFFu);

    m_quads.push_back(quad);
}

void VkSpriteBatch::buildTestScene(const VkExtent2D& extent)
{
    // Stage 3 visual test: atlas tiles laid out in a grid. Each comes from a different PNG,
    // some from a different atlas LAYER, and all go in a single draw call - if
    // the full set of images is visible on screen, it means the atlas, packing, layer indexing
    // and the batch all work at once.
    begin();

    constexpr float kCell = 112.0f;    // spacing between tile centers
    constexpr float kTile = 96.0f;     // longest tile side after scaling
    constexpr float kMargin = 16.0f;

    const float usable = static_cast<float>(extent.width) - 2.0f * kMargin;
    int columns = static_cast<int>(usable / kCell);
    if (columns < 1)
        columns = 1;

    for (size_t i = 0; i < m_testSlots.size(); ++i) {
        const VkAtlasSlot& slot = m_testSlots[i];

        const int column = static_cast<int>(i) % columns;
        const int row = static_cast<int>(i) / columns;

        // Uniform scale (rather than stretching to the cell) so proportions are preserved -
        // a skewed tile shape would immediately betray a bug in the atlas coordinates.
        const float longest = static_cast<float>(std::max(slot.width, slot.height));
        const float scale = longest > 0.0f ? kTile / longest : 1.0f;
        const float w = static_cast<float>(slot.width) * scale;
        const float h = static_cast<float>(slot.height) * scale;

        const float cellX = kMargin + static_cast<float>(column) * kCell;
        const float cellY = kMargin + static_cast<float>(row) * kCell;

        drawSprite(cellX + (kTile - w) * 0.5f, cellY + (kTile - h) * 0.5f, w, h, slot);
    }
}

void VkSpriteBatch::record(VkCommandBuffer cmd, const VkExtent2D& extent, const uint32_t frameIndex)
{
    m_drawCalls = 0;

    // We ALWAYS clear the external-feeding flag at the start: if the feeder stops
    // feeding (or a frame drops due to an error), the next frame goes back to the test scene
    // and it is immediately VISIBLE that something died, instead of a frozen last image.
    const bool external = m_externallyFed;
    m_externallyFed = false;

    if (!m_ready || cmd == VK_NULL_HANDLE || extent.width == 0 || extent.height == 0)
        return;

    if (frameIndex >= m_vertexMapped.size() || m_vertexMapped[frameIndex] == nullptr)
        return;

    if (external) {
        recordExternal(cmd, extent, frameIndex);
        return;
    }

    // Stage 3: the batch itself builds the tile list (test scene). Since stage 4 this is a FALLBACK -
    // normally the tiles come from the real drawing queue through beginExternal().
    buildTestScene(extent);

    if (m_quads.empty() || !syncDescriptor())
        return;

    uint32_t quadCount = static_cast<uint32_t>(m_quads.size());
    if (quadCount > kMaxQuads) {
        // We truncate instead of reallocating: reallocating the buffer in the middle of recording
        // a frame would require waiting for the card, turning a limit overrun into a visible stutter.
        g_logger.warning("[vulkan] batch: {} tiles exceed the {} limit - excess skipped",
                         quadCount, kMaxQuads);
        quadCount = kMaxQuads;
    }

    // The write goes STRAIGHT into card-visible memory - no intermediate vector and no memcpy
    // of the whole buffer. That is the entire difference versus the GL path's client-side vertex
    // arrays, where the same data traveled through several copies before reaching the driver.
    auto* vertices = static_cast<VkSpriteVertex*>(m_vertexMapped[frameIndex]);

    for (uint32_t i = 0; i < quadCount; ++i) {
        const VkSpriteQuad& q = m_quads[i];
        VkSpriteVertex* v = vertices + static_cast<size_t>(i) * 4;

        const float x0 = q.x;
        const float y0 = q.y;
        const float x1 = q.x + q.w;
        const float y1 = q.y + q.h;

        // Corner order must match the index buffer: 0=top-left, 1=top-right,
        // 2=bottom-right, 3=bottom-left.
        v[0].pos[0] = x0; v[0].pos[1] = y0; v[0].uv[0] = q.uvMin[0]; v[0].uv[1] = q.uvMin[1];
        v[1].pos[0] = x1; v[1].pos[1] = y0; v[1].uv[0] = q.uvMax[0]; v[1].uv[1] = q.uvMin[1];
        v[2].pos[0] = x1; v[2].pos[1] = y1; v[2].uv[0] = q.uvMax[0]; v[2].uv[1] = q.uvMax[1];
        v[3].pos[0] = x0; v[3].pos[1] = y1; v[3].uv[0] = q.uvMin[0]; v[3].uv[1] = q.uvMax[1];

        for (int k = 0; k < 4; ++k) {
            v[k].layer = q.layer;
            std::memcpy(v[k].color, q.color, sizeof(q.color));
        }
    }

    VkViewport viewport{};
    viewport.x = 0.0f;
    viewport.y = 0.0f;
    viewport.width = static_cast<float>(extent.width);
    viewport.height = static_cast<float>(extent.height);
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;

    VkRect2D scissor{};
    scissor.offset = { 0, 0 };
    scissor.extent = extent;

    m_vkCmdSetViewport(cmd, 0, 1, &viewport);
    m_vkCmdSetScissor(cmd, 0, 1, &scissor);

    m_vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, m_pipeline);

    const VkDeviceSize offset = 0;
    m_vkCmdBindVertexBuffers(cmd, 0, 1, &m_vertexBuffers[frameIndex], &offset);
    m_vkCmdBindIndexBuffer(cmd, m_indexBuffer, 0, VK_INDEX_TYPE_UINT32);

    // ONE descriptor bind for the whole frame - regardless of how many layers the atlas has
    // and how many different images the tiles come from.
    m_vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, m_pipelineLayout,
                              0, 1, &m_descriptorSet, 0, nullptr);

    VkSpritePushConstants push{};
    push.invHalfSize[0] = 2.0f / static_cast<float>(extent.width);
    push.invHalfSize[1] = 2.0f / static_cast<float>(extent.height);

    m_vkCmdPushConstants(cmd, m_pipelineLayout, VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(push), &push);

    // ONE draw call for all tiles - that is the goal of stage 3.
    m_vkCmdDrawIndexed(cmd, quadCount * 6, 1, 0, 0, 0);
    m_drawCalls = 1;

    ++m_frameCounter;

    // Diagnostics: the first frame (confirmation the batch started) and then every ~10 seconds,
    // so the log does not bloat at 60 frames per second.
    if (m_frameCounter == 1 || (m_frameCounter % 600) == 0) {
        g_logger.info("[vulkan] frame {}: atlas tiles {}, layers {}, atlas VRAM {:.2f} MB, "
                      "occupancy {:.1f}%, tiles in frame {}, draw calls {}",
                      m_frameCounter, m_atlas.getTileCount(), m_atlas.getLayerCount(),
                      static_cast<double>(m_atlas.getGpuBytes()) / (1024.0 * 1024.0),
                      m_atlas.getOccupancy() * 100.0f, quadCount, m_drawCalls);
    }
}

void VkSpriteBatch::recordExternal(VkCommandBuffer cmd, const VkExtent2D& extent, const uint32_t frameIndex)
{
    if (m_vertices.empty() || !syncDescriptor())
        return;

    // allocVertices enforces the limit while appending, but punchRect can slightly GROW
    // the geometry (clipped triangles split into several) - hence the second safety check here.
    uint32_t vertexCount = static_cast<uint32_t>(m_vertices.size());
    if (vertexCount > kMaxVertices) {
        m_droppedVertices += vertexCount - kMaxVertices;
        vertexCount = kMaxVertices - (kMaxVertices % 3);
    }

    std::memcpy(m_vertexMapped[frameIndex], m_vertices.data(),
                static_cast<size_t>(vertexCount) * sizeof(VkSpriteVertex));

    VkViewport viewport{};
    viewport.x = 0.0f;
    viewport.y = 0.0f;
    viewport.width = static_cast<float>(extent.width);
    viewport.height = static_cast<float>(extent.height);
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;

    m_vkCmdSetViewport(cmd, 0, 1, &viewport);

    const VkDeviceSize offset = 0;
    m_vkCmdBindVertexBuffers(cmd, 0, 1, &m_vertexBuffers[frameIndex], &offset);

    // The index buffer stays unbound: the external mode draws a raw triangle list.
    // ONE descriptor bind for the whole frame - exactly like in the test scene.
    m_vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, m_pipelineLayout,
                              0, 1, &m_descriptorSet, 0, nullptr);

    VkSpritePushConstants push{};
    push.invHalfSize[0] = 2.0f / static_cast<float>(extent.width);
    push.invHalfSize[1] = 2.0f / static_cast<float>(extent.height);

    m_vkCmdPushConstants(cmd, m_pipelineLayout, VK_SHADER_STAGE_VERTEX_BIT, 0, sizeof(push), &push);

    // One segment = one scissor + one pipeline = one vkCmdDraw. Changes are rare
    // (clipRect in the UI, MULTIPLY on outfit masks), so a game frame is usually
    // a handful to a dozen-plus draw calls.
    uint8_t boundPipeline = UINT8_MAX;

    for (const Segment& segment : m_segments) {
        if (segment.count == 0 || segment.first >= vertexCount)
            continue;

        // clamp to the capacity safety check (see above)
        const uint32_t count = std::min(segment.count, vertexCount - segment.first);
        if (count < 3)
            continue;

        if (segment.pipeline != boundPipeline) {
            m_vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS,
                                segment.pipeline == 1 ? m_pipelineMultiply : m_pipeline);
            boundPipeline = segment.pipeline;
        }

        m_vkCmdSetScissor(cmd, 0, 1, &segment.scissor);
        m_vkCmdDraw(cmd, count - (count % 3), 1, segment.first, 0);
        ++m_drawCalls;
    }

    ++m_frameCounter;

    if (m_frameCounter == 1 || (m_frameCounter % 600) == 0) {
        g_logger.info("[vulkan] frame {} (game queue): vertices {}, segments {}, draw calls {}, "
                      "atlas tiles {}, layers {}, atlas VRAM {:.2f} MB, occupancy {:.1f}%{}",
                      m_frameCounter, vertexCount, m_segments.size(), m_drawCalls,
                      m_atlas.getTileCount(), m_atlas.getLayerCount(),
                      static_cast<double>(m_atlas.getGpuBytes()) / (1024.0 * 1024.0),
                      m_atlas.getOccupancy() * 100.0f,
                      m_droppedVertices > 0 ? fmt::format(", dropped vertices {}", m_droppedVertices) : "");
    }
}

void VkSpriteBatch::terminate()
{
    // Note: we do NOT call vkDeviceWaitIdle here - VkContext::terminate does it before calling us,
    // and on an init() failure nothing has reached the drawing queue yet.
    if (m_device == VK_NULL_HANDLE) {
        m_ready = false;
        return;
    }

    if (m_pipeline != VK_NULL_HANDLE && m_vkDestroyPipeline) {
        m_vkDestroyPipeline(m_device, m_pipeline, nullptr);
        m_pipeline = VK_NULL_HANDLE;
    }

    if (m_pipelineMultiply != VK_NULL_HANDLE && m_vkDestroyPipeline) {
        m_vkDestroyPipeline(m_device, m_pipelineMultiply, nullptr);
        m_pipelineMultiply = VK_NULL_HANDLE;
    }

    if (m_pipelineLayout != VK_NULL_HANDLE && m_vkDestroyPipelineLayout) {
        m_vkDestroyPipelineLayout(m_device, m_pipelineLayout, nullptr);
        m_pipelineLayout = VK_NULL_HANDLE;
    }

    // Descriptor sets die together with the pool - they need not (and without the right flag
    // cannot) be freed individually.
    if (m_descriptorPool != VK_NULL_HANDLE && m_vkDestroyDescriptorPool) {
        m_vkDestroyDescriptorPool(m_device, m_descriptorPool, nullptr);
        m_descriptorPool = VK_NULL_HANDLE;
    }
    m_descriptorSet = VK_NULL_HANDLE;
    m_descriptorGeneration = UINT32_MAX;

    if (m_descriptorLayout != VK_NULL_HANDLE && m_vkDestroyDescriptorSetLayout) {
        m_vkDestroyDescriptorSetLayout(m_device, m_descriptorLayout, nullptr);
        m_descriptorLayout = VK_NULL_HANDLE;
    }

    // The atlas AFTER the pipeline and descriptors: it holds the view the descriptor set pointed at.
    m_atlas.terminate();

    for (size_t i = 0; i < m_vertexBuffers.size(); ++i) {
        // Unmap before freeing the memory - vkFreeMemory on mapped memory is
        // a usage error, even if most drivers forgive it.
        if (m_vertexMapped[i] != nullptr && m_vkUnmapMemory) {
            m_vkUnmapMemory(m_device, m_vertexMemories[i]);
            m_vertexMapped[i] = nullptr;
        }

        if (m_vertexBuffers[i] != VK_NULL_HANDLE && m_vkDestroyBuffer) {
            m_vkDestroyBuffer(m_device, m_vertexBuffers[i], nullptr);
            m_vertexBuffers[i] = VK_NULL_HANDLE;
        }

        if (m_vertexMemories[i] != VK_NULL_HANDLE && m_vkFreeMemory) {
            m_vkFreeMemory(m_device, m_vertexMemories[i], nullptr);
            m_vertexMemories[i] = VK_NULL_HANDLE;
        }
    }

    m_vertexBuffers.clear();
    m_vertexMemories.clear();
    m_vertexMapped.clear();

    if (m_indexBuffer != VK_NULL_HANDLE && m_vkDestroyBuffer) {
        m_vkDestroyBuffer(m_device, m_indexBuffer, nullptr);
        m_indexBuffer = VK_NULL_HANDLE;
    }

    if (m_indexMemory != VK_NULL_HANDLE && m_vkFreeMemory) {
        m_vkFreeMemory(m_device, m_indexMemory, nullptr);
        m_indexMemory = VK_NULL_HANDLE;
    }

    if (m_fragShader != VK_NULL_HANDLE && m_vkDestroyShaderModule) {
        m_vkDestroyShaderModule(m_device, m_fragShader, nullptr);
        m_fragShader = VK_NULL_HANDLE;
    }

    if (m_vertShader != VK_NULL_HANDLE && m_vkDestroyShaderModule) {
        m_vkDestroyShaderModule(m_device, m_vertShader, nullptr);
        m_vertShader = VK_NULL_HANDLE;
    }

    m_quads.clear();
    m_quads.shrink_to_fit();
    m_testSlots.clear();
    m_testSlots.shrink_to_fit();
    m_vertices.clear();
    m_vertices.shrink_to_fit();
    m_segments.clear();
    m_segments.shrink_to_fit();
    m_externallyFed = false;

    // We do NOT destroy handles borrowed from VkContext - they are not ours. We only zero them
    // so that a repeated terminate() is safe.
    m_device = VK_NULL_HANDLE;
    m_physicalDevice = VK_NULL_HANDLE;
    m_renderPass = VK_NULL_HANDLE;
    m_graphicsQueue = VK_NULL_HANDLE;
    m_commandPool = VK_NULL_HANDLE;

    m_ready = false;
}

#endif // WIN32
