import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import '../../models/car.dart';
import '../../providers/repair_provider.dart';

class AddRepairPage extends StatefulWidget {
  final int? carId;
  final String? plateNumber;

  const AddRepairPage({super.key, this.carId, this.plateNumber});

  @override
  State<AddRepairPage> createState() => _AddRepairPageState();
}

class _AddRepairPageState extends State<AddRepairPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加维修记录'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '维修记录信息',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.plateNumber == null)
                        FormBuilderTextField(
                          name: 'plateNumber',
                          decoration: const InputDecoration(
                            labelText: '车牌号码 *',
                            hintText: '例如：京A12345',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_car),
                          ),
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(
                                errorText: '请输入车牌号码'),
                          ]),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      if (widget.plateNumber == null)
                        const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'repairShop',
                        decoration: const InputDecoration(
                          labelText: '维修店名称 *',
                          hintText: '例如：XX汽修厂',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '请输入维修店名称'),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.grey),
                              const SizedBox(width: 12),
                              Text(
                                '维修日期: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'description',
                        decoration: const InputDecoration(
                          labelText: '维修项目 *',
                          hintText: '例如：更换机油、修理刹车',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.build),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '请输入维修项目'),
                        ]),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'cost',
                        decoration: const InputDecoration(
                          labelText: '维修费用 *',
                          hintText: '例如：500.00',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          suffixText: '元',
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(errorText: '请输入维修费用'),
                          FormBuilderValidators.numeric(errorText: '请输入有效金额'),
                          FormBuilderValidators.min(0, errorText: '费用不能为负数'),
                        ]),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'mileage',
                        decoration: const InputDecoration(
                          labelText: '里程数',
                          hintText: '例如：50000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.speed),
                          suffixText: '公里',
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.integer(errorText: '请输入有效里程数'),
                          FormBuilderValidators.min(0, errorText: '里程数不能为负数'),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<String>(
                        name: 'repairType',
                        decoration: const InputDecoration(
                          labelText: '维修类型',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'maintenance', child: Text('保养维护')),
                          DropdownMenuItem(
                              value: 'repair', child: Text('故障维修')),
                          DropdownMenuItem(
                              value: 'replacement', child: Text('零件更换')),
                          DropdownMenuItem(
                              value: 'upgrade', child: Text('改装升级')),
                          DropdownMenuItem(
                              value: 'inspection', child: Text('检查检验')),
                          DropdownMenuItem(value: 'other', child: Text('其他')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: 'notes',
                        decoration: const InputDecoration(
                          labelText: '备注',
                          hintText: '其他说明信息',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDate() {
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      onConfirm: (date) {
        setState(() {
          _selectedDate = date;
        });
      },
      currentTime: _selectedDate,
      maxTime: DateTime.now(),
      locale: LocaleType.zh,
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;

        final repair = Repair(
          carId: widget.carId ?? 0,
          repairDate: _selectedDate,
          item: formData['description'],
          price: double.parse(formData['cost']),
          note: formData['notes'],
          garageName: formData['repairShop'],
        );

        final repairProvider =
            Provider.of<RepairProvider>(context, listen: false);
        final success = await repairProvider.addRepair(repair);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('维修记录添加成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(repairProvider.error ?? '添加维修记录失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('添加维修记录失败: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
