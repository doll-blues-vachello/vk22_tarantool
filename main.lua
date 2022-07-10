local vips = require "vips"
local Multipart = require("multipart")

-- local image = vips.Image.new_from_file("meme.png", { access = "sequential" })

function string_simil (fx, fy)
    local n = string.len(fx)
    local m = string.len(fy)
    local ssnc = 0
  
    if n > m then
      fx, fy = fy, fx
      n, m = m, n
    end
  
    for i = n, 1, -1 do
      if i <= string.len(fx) then
      for j = 1, n-i+1, 1 do
          local pattern = string.sub(fx, j, j+i-1)
          if string.len(pattern) == 0 then break end
          local found_at = string.find(fy, pattern)
          if found_at ~= nil then
            ssnc = ssnc + (2*i)^2
            fx = string.sub(fx, 0, j-1) .. string.sub(fx, j+i)
            fy = string.sub(fy, 0, found_at-1) .. string.sub(fy, found_at+i)
            break
          end
        end
      end
    end
  
    return (ssnc/((n+m)^2))^(1/2)
  
  end

local function make_meme(image, up_text, down_text)
    local function gen_text(text, width, height)
        text_img = vips.Image.text(text, {width=width, height=height, autofit_dpi=true, rgba=true, align="centre", justify=true})
        return text_img:gravity("centre", width, height, {extend="background",background={0,0,0,0}})

    end
    up_text = gen_text(up_text, image:width(), image:height()*0.3)
    down_text = gen_text(down_text, image:width(), image:height()*0.3)
    image=image:composite(up_text,"over", {x=0, y=0})
    image=image:composite(down_text, "over", {x=0, y=image:height()*0.7})
    return image
end

local function init_space()
    box.schema.sequence.create('S',{min=1, start=1, if_not_exists=true})
    local spc = box.schema.space.create('vk22', {format = {{'id', 'unsigned'}, {'up_text', 'string'}, {'down_text', 'string'}, {'image', 'string'}}, if_not_exists = true})
    spc:create_index('id', {parts={'id'}, if_not_exists=true,unique=true, sequence='S'})
end

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end


local function set_meme(req)
    local multipart_data = Multipart(req:read(), req.headers["content-type"])
    local t = multipart_data:get_all()
    -- print(dump(t))

    local up_text = t['top']
    local down_text = t['bottom']
    local image = t['image']

    if up_text == nil and down_text == nil and image ~= nil then
        return {status=200, body="Id of meme with similiar image"}
    end

    if up_text == nil then
        up_text = ""
    end

    if down_text == nil then 
        down_text = ""
    end


    if image == nil then
        -- search for image with similiar text
        local max_score = -1
        local max_id = -1
        for i,v in ipairs(box.space.vk22:select({}, {fullscan=true})) do 
            local score = string_simil(up_text..down_text, v[2]..v[3])
            if score > max_score then
                max_score = score
                max_id = v[1]
            end
        end
        return {status=200, body=tostring(max_id)}
    end


    local res = box.space.vk22:insert{nil, up_text, down_text, image}

    -- print(dump(res))
    return {status=200, body=tostring(res[1])}
    
end

local function get_meme(req)
    -- TODO: check for unknown id
    local id = tonumber(req:query_param('id'))
    local meme = box.space.vk22:get(id)

    image = vips.Image.new_from_buffer(meme[4])
    image=make_meme(image, meme[2], meme[3])

    local buff = image:write_to_buffer(".png")

    return {status=200, headers={['content-type'] = 'image/png'}, body=buff}
end

local function random_meme(req)
    local text_meme = box.space.vk22.index.id:random(math.random(1, 1000000000))
    local image_meme = box.space.vk22.index.id:random(math.random(1, 1000000000))

    image = vips.Image.new_from_buffer(image_meme[4])
    image=make_meme(image, text_meme[2], text_meme[3])

    local buff = image:write_to_buffer(".png")

    return {status=200, headers={['content-type'] = 'image/png'}, body=buff}
end

local function init()
    math.randomseed(os.time())

    box.cfg{
        vinyl_dir = './data',
        memtx_dir = './data',
        wal_dir = './data',
    }
    init_space()

    local httpd = require('http.server').new('0.0.0.0', 1337)
    httpd:route({path = '/set', method = 'POST'}, set_meme)
    httpd:route({path = '/get', method = 'GET'}, get_meme)
    httpd:route({path = '/random', method = 'GET'}, random_meme)
    -- httpd:route({ path = '/', file = 'index.html' })


    httpd:start()

end


init()
-- make_meme(image, "top asegrhdwteryjwaw AREWTRJT", "bo"):write_to_file("inv.png")
