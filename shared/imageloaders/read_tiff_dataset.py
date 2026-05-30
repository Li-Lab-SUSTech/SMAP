from pycromanager import *

#This path is to the top level of the dataset
# data_path = os.path.split(__file__)[0]+'\\py_acq_1'
# 680nm_-1um_1um_50nm_30ms_exposure=30.002887218045114_NDTiffStack.tif
# data_path = os.path.split(__file__)[0]+'\\680nm_-1um_1um_50nm_30ms_exposure=30.002887218045114_1'
# data_path = 'D:\\JinL\\matlab\\py_cam_sample\\680nm_-1um_1um_50nm_30ms_exposure=30.002887218045114_1'

def read_tiff_metadata(data_path):
    dataset = Dataset(data_path)

    keys = dataset.get_index_keys()
    t0_key = keys[0]
    t0_metadata = dataset.read_metadata(channel=t0_key['channel'],time=t0_key['time'],z=t0_key['z'])

    metadata_list = []
    for key in t0_metadata:
        metadata_list.append([key,t0_metadata[key]])
        # print(key, t0_metadata[key])

    print(metadata_list)

    return metadata_list

# def read_tiff_info(data_path):
#     metadata_list = read_tiff_metadata(data_path)
#     # print(t0_metadata)
#     print('ROI: '+t0_metadata['ROI'])
#     print('Exposure: '+str(t0_metadata['Exposure']))
#     print('HamamatsuHam_DCAM-CameraID: '+str(t0_metadata['HamamatsuHam_DCAM-CameraID']))

#     cameraID = t0_metadata['HamamatsuHam_DCAM-CameraID']
#     return cameraID

if __name__ == '__main__':
    data_path = 'D:\\JinL\\matlab\\py_cam_sample\\680nm_-1um_1um_50nm_30ms_exposure=30.002887218045114_1'

    metadata_list = read_tiff_metadata(data_path)
    print(metadata_list(0,0))