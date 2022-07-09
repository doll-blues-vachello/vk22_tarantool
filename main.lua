local vips = require "vips"
local Multipart = require("multipart")

-- local image = vips.Image.new_from_file("meme.png", { access = "sequential" })


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

local function init()
    box.cfg()
    init_space()

    local httpd = require('http.server').new('0.0.0.0', 1337)
    httpd:route({path = '/set', method = 'POST'}, set_meme)
    httpd:route({path = '/get', method = 'GET'}, get_meme)


    httpd:start()

end


init()
-- make_meme(image, "top asegrhdwteryjwaw AREWTRJT", "bo"):write_to_file("inv.png")
